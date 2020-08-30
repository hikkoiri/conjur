require 'command_class'
require 'uri'
require 'websocket'
require 'rubygems/package'

require 'active_support/time'
require 'websocket-client-simple'

module Authentication
  module AuthnK8s

    KubectlExec ||= CommandClass.new(
      dependencies: {
        logger: Rails.logger
      },
      inputs: %i( k8s_object_lookup
                  pod_namespace
                  pod_name
                  container
                  cmds
                  body
                  stdin )
    ) do

      DEFAULT_KUBECTL_EXEC_COMMAND_TIMEOUT = 5

      def call
        @logger.debug(
          LogMessages::Authentication::AuthnK8s::PodExecCommand.new(
            @cmds.join(" "),
            @container,
            @pod_name
          )
        )

        @message_log    = MessageLog.new
        @channel_closed = false

        url       = server_url(@cmds, @stdin)
        headers   = kubeclient.headers.clone
        ws_client = WebSocket::Client::Simple.connect(url, headers: headers)

        add_websocket_event_handlers(ws_client, @body, @stdin)

        wait_for_close_message

        unless @channel_closed
          raise Errors::Authentication::AuthnK8s::CommandTimedOut.new(
            timeout,
            @container,
            @pod_name
          )
        end

        # TODO: raise an `WebsocketServerFailure` here in the case of ws :error

        @message_log.messages
      end

      def on_open(ws_client, body, stdin)
        hs       = ws_client.handshake
        hs_error = hs.error

        if hs_error
          ws_client.emit(:error, "Websocket handshake error: #{hs_error.inspect}")
        else
          @logger.debug(
            LogMessages::Authentication::AuthnK8s::PodChannelOpen.new(@pod_name)
          )

          if stdin
            data = WebSocketMessage.channel_byte('stdin') + body
            ws_client.send(data)
          end
        end
      end

      def on_message(msg, ws_client)
        wsmsg = WebSocketMessage.new(msg)

        msg_type = wsmsg.type
        msg_data = wsmsg.data

        if msg_type == :binary
          if msg_data.to_s.strip.empty?
            @logger.debug(LogMessages::Authentication::AuthnK8s::PodExecCommandEnd.new)
            ws_client.send(nil, type: :close)
          else
            @logger.debug(
              LogMessages::Authentication::AuthnK8s::PodChannelData.new(
                @pod_name,
                wsmsg.channel_name,
                msg_data
              )
            )
            @message_log.save_message(wsmsg)
          end
        elsif msg_type == :close
          @logger.debug(
            LogMessages::Authentication::AuthnK8s::PodMessageData.new(
              @pod_name,
              "close",
              msg_data
            )
          )
          ws_client.close
        end
      end

      def on_close
        @channel_closed = true
        @logger.debug(
          LogMessages::Authentication::AuthnK8s::PodChannelClosed.new(@pod_name)
        )
      end

      def on_error(err)
        @channel_closed = true

        error_info = err.inspect
        @logger.debug(
          LogMessages::Authentication::AuthnK8s::PodError.new(@pod_name, error_info)
        )
        @message_log.save_error_string(error_info)
      end

      private

      def kubeclient
        @kubeclient ||= @k8s_object_lookup.kubectl_client
      end

      def add_websocket_event_handlers(ws_client, body, stdin)
        kubectl = self

        ws_client.on(:open) { kubectl.on_open(ws_client, body, stdin) }
        ws_client.on(:message) { |msg| kubectl.on_message(msg, ws_client) }
        ws_client.on(:close) { kubectl.on_close }
        ws_client.on(:error) { |err| kubectl.on_error(err) }
      end

      def wait_for_close_message
        (timeout / 0.1).to_i.times do
          break if @channel_closed
          sleep 0.1
        end
      end

      def query_string(cmds, stdin)
        stdin_part = stdin ? ['stdin=true'] : []
        cmds_part  = cmds.map { |cmd| "command=#{CGI.escape(cmd)}" }
        (base_query_string_parts + stdin_part + cmds_part).join("&")
      end

      def base_query_string_parts
        ["container=#{CGI.escape(@container)}", "stderr=true", "stdout=true"]
      end

      def server_url(cmds, stdin)
        api_uri  = kubeclient.api_endpoint
        base_url = "wss://#{api_uri.host}:#{api_uri.port}"
        path     = "/api/v1/namespaces/#{@pod_namespace}/pods/#{@pod_name}/exec"
        query    = query_string(cmds, stdin)
        "#{base_url}#{path}?#{query}"
      end

      def timeout
        return @timeout if @timeout

        if ENV["KUBECTL_EXEC_COMMAND_TIMEOUT"].to_s.strip.empty?
          @timeout = DEFAULT_KUBECTL_EXEC_COMMAND_TIMEOUT
        else
          @timeout = ENV["KUBECTL_EXEC_COMMAND_TIMEOUT"].to_i
        end
      end
    end

    class KubectlExec
      # This delegates to all the work to the call method created automatically
      # by CommandClass
      #
      # This is needed because we need these methods to exist on the class,
      # but that class contains only a metaprogramming generated `call()`.
      def execute(k8s_object_lookup:,
        pod_namespace:,
        pod_name:,
        cmds:,
        container: 'authenticator',
        body: "",
        stdin: false)
        call(
          k8s_object_lookup: k8s_object_lookup,
          pod_namespace:     pod_namespace,
          pod_name:          pod_name,
          container:         container,
          cmds:              cmds,
          body:              body,
          stdin:             stdin
        )
      end

      def copy(k8s_object_lookup:,
        pod_namespace:,
        pod_name:,
        path:,
        content:,
        mode:,
        container: 'authenticator')
        execute(
          k8s_object_lookup: k8s_object_lookup,
          pod_namespace:     pod_namespace,
          pod_name:          pod_name,
          container:         container,
          cmds:              %w(tar xvf - -C /),
          body:              tar_file_as_string(path, content, mode),
          stdin:             true
        )
      end

      private

      def tar_file_as_string(path, content, mode)
        tarfile = StringIO.new("")

        Gem::Package::TarWriter.new(tarfile) do |tar|
          tar.add_file(path, mode) do |tf|
            tf.write(content)
          end
        end

        tarfile.string
      end
    end

    # Utility class for processing WebSocket messages.
    class WebSocketMessage
      class << self
        def channel_byte(channel_name)
          channel_number_from_name(channel_name).chr
        end

        def channel_number_from_name(channel_name)
          channel_names.index(channel_name)
        end

        def channel_names
          %w(stdin stdout stderr error resize)
        end
      end

      def initialize(msg)
        @msg = msg
      end

      def type
        @msg.type
      end

      def data
        @msg.data[1..-1]
      end

      def channel_name
        self.class.channel_names[channel_number]
      end

      def channel_number
        unless @msg.respond_to?(:data)
          return self.class.channel_number_from_name('error')
        end

        @msg.data[0..0].bytes.first
      end
    end
  end
end
