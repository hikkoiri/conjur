# Variable Schema Validation Proposal

- [Variable Schema Validation Proposal](#variable-schema-validation-proposal)
  - [Introduction](#introduction)
  - [Proposed Solution](#proposed-solution)
    - [User Experience](#user-experience)
    - [Functionality](#functionality)
      - [Input Validation](#input-validation)
      - [Secrets Encryption](#secrets-encryption)
      - [Builtin Schemas](#builtin-schemas)
      - [Additional Required Functionality](#additional-required-functionality)
  - [Main Advantages of This Proposal](#main-advantages-of-this-proposal)
  - [Affected Areas](#affected-areas)
  - [Backwards Compatibility](#backwards-compatibility)
  - [Performance](#performance)
  - [Security](#security)
  - [Documentation](#documentation)
  - [Version Update](#version-update)
  - [Future Work](#future-work)
  - [Delivery Plan](#delivery-plan)
  
## Introduction

Conjur variables are resources that allow a user or an application to define and store sensitive information.

In many cases, such sensitive information is comprised of multiple pieces that are tightly coupled and together represent a complete object. A few examples:

- In order to access a MySQL database, a user needs a username, a password and an address, URL or connection string.
- In order to access a REST API exposed by a certain service, a user might need either a username and password, a private key and a public certificate, or a token. In addition, the user will need the server public certificate and its address.

Currently, this is handled by defining multiple variables in Conjur. Each variable contains a single value, such as a username, a password, etc. To bundle these pieces together, we use a naming convention. For example:

```yaml
- !policy
  id: my-policy
  body:
    - &vars
      - !variable mysql-db-creds/password
      - !variable mysql-db-creds/username
      - !variable mysql-db-creds/address
      - !variable mysql-db-creds/port

    - !host my-app
    
    - !permit
      role: !host my-app
      privileges: [ read,execute ]
      resource: *vars
```

## Proposed Solution

The proposed solution is to add the ability to use JSON schemas and link them to variables, for which we want validation of their content. This will allow a single variable to store multiple, related values. While it's already possible today, to store JSON structured information in a variable, this proposed feature adds two added values:

- The JSON structure is validated and enforced. If the input is invalid, the user will get a proper error message and the variable update will be denied.
- The JSON structure will not be encrypted completely, but only the sensitive information. This will allow future seach capabilities based on the non sensitive information.

### User Experience

Let's have a look at the following example:

```yaml
- !policy
  id: my-policy
  body:
  - !variable
    id: mysql-db-creds
    schema: !variable /conjur/schemas/mysql-schema

  - !host my-app
  
  - !permit
    role: !host my-app
    privileges: [ read,execute ]
    resource: !variable mysql-db-creds
```

And

```yaml
- !policy
  id: conjur/schemas
  body:
  - &schemas
    - !variable mysql-schema
  
  - !permit
    role: !group /conjur/all
    privileges: [ read,execute ]
    resource: !variable *schemas
```

In the example above, the `/conjur/schemas/mysql-schema` variable will be updated with the following value:

```json
{
  "$id": "https://cyberark.com/mysql.schema.json",
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "MySQL Creds",
  "type": "object",
  "properties": {
    "username": {
      "type": "string",
      "description": "The MySQL username"
    },
    "password": {
      "type": "string",
      "description": "The MySQL password",
      "minLength": 12,
      "maxLength": 40,
      "pattern": "[A-Za-z0-9]"
    },
    "address": {
      "type": "string",
      "description": "The MySQL address"
    },
    "port": {
      "description": "The MySQL port number",
      "type": "integer",
      "minimum": 1,
      "maximum": 65535
    }
  },
  "required": ["username", "password"],
  "additionalProperties": false,
  "secrets": [
      "password",
    ]
}
```

And the `mysql-db-creds` variable could be updated with the following value:

```json
{
  "username": "my-user",
  "password": "my-password-12345",
  "address": "my-db.com",
  "port": 3306
}
```

### Functionality

#### Input Validation

Conjur will validate the variable content, using the JSON schema that is specified in the `schema` attribure of that variable.

For the example above, Conjur will use the JSON schema specified in `conjur/schemas/mysql-schema` to verify the content of `mysql-db-creds`. This verification includes:

- `username` and `password` are mandatory properties.
- `address` and `port` are allowed properties.
- `port` must contain a valid port number.
- `password` must align to a sufficient complexity.

If the varialbe content is invalid, the user will get an HTTP code of 422 (Unprocessable Entity) and the body of the response will also contain an elaborative error message that explains what part of the input was found to be invalid.

#### Secrets Encryption

The JSON schema can contain a property called `secrets` which expects an array of JSON schema property names. The properties specified in this array, will be encrypted in the database. All the rest of the properties and the JSON structure will remain in cleartext. This allows the protection of sensitive data while also allowing the non-sensitive values to be searchable.

For the example above, the `mysql-db-creds` variable will be saved in the database as follows:

```json
{
  "username": "my-user",
  "password": "U2FsdGVkX19Ji6JpgnVHW3V47OtMJwuKi1Yf9nc0aP5QcuzdnIrpzZ2zMC90f24g",
  "address": "my-db.com",
  "port": 3306
}
```

Before the variable value is returned to the client, the secret attributes are decrypted so that the given example above, would look like this:

```json
{
  "username": "my-user",
  "password": "my-password",
  "address": "my-db.com",
  "port": 3306
}
```

#### Builtin Schemas

To simplify the user experience, Conjur can come with prdefined JSON schemas for the most common secrets use cases. The list of predefined schmeas should include:

- Database secrets - Oracle, MSSQL, MySQL, Postgres, MariaDB, DB2.
- Cloud access keys - AWS, Azure, GCP.
- X509 certificates.
- JWTs

Write about the advantages of atomicity, minimal changes in the database to implement this and so on.

#### Additional Required Functionality

In order to provide access for any role to the builtin schemas, a new builtin group should be introduced: `conjur/all`. All roles in the Conjur account should be added to this group automatically, thus keeping this group always up to date with all the roles that exist in the account.

Usage example:

```yaml
- !permit
  role: !group /conjur/all
  privileges: [ read,execute ]
  resource: !variable my-var
```

## Main Advantages of This Proposal

- The feature does not require changes in the database schma, only in new builtin content.
- The returned variable is in a JSON structure, same as the rest of our APIs responses.
- We leverage a standard way to enforce the content of the varialbe, with a well known JSON schema.
- Tightly coupled values, such as username and password, are updated together in a single transaction. This will prevent momentary inconsistency in which each value was updated independently, one after the other.

## Affected Areas

- The new functionality will be developed in the Conjur server and the policy parser.
- No new APIs are needed, since all the functionality will be given as part of the policy loading.
- No changes required in the database structure. But new builtin data should be added into the database tables, when they are initially created (clean install) or when an upgrade occurs from any prioir version.

## Backwards Compatibility

Variables that do not have a link to a schema, will not enforce the content. Therefore, behavior of all existing variables and newly created variables without the schema attribute, will work the same as it has been working.

## Performance

Performance tests are required in order to make sure the schema validation doesn't introduce a major performance effect. The risk of a significant performance change is low.

## Security

Introducing a new `conjur/all` group can potentially be dangerous for uncautios users. Any permission given to that group will be given to all roles in the Conjur account, so proper warnings should be given to the user, at least in our documentation.

## Documentation

We will need to update the docs of this new functionality, under the policy management section. The documentation should include the following:

- How the variable schema validation works
- How can a user use the builtin schemas
- How can a user create new schemas
- Policy examples with schema examples. Explain how the variable content is enforced in these examples.

## Version Update

This feature requires a Conjur release.

## Future Work

Modify our examples and integrations, such as the Conjur Summon provider, to leverage this new single variable JSON structure, instead of multiple variables.

## Delivery Plan

Rough estimations of the high level delivery plan includes the following steps:

| Functionality                                                    | Dev    | Tests  |
|------------------------------------------------------------------|--------|--------|
| Adding a new `schema` attribute to the variables policy syntax   | 3 days | 3 days |
| Adding builtin schemas to the database migration process         | 5 days | 2 days |
| Adding builtin `all` group                                       | 2 days | 2 days |
| Every new role is automatically added to the `all` group         | 4 days | 2 days |
| Adding JSON schema enforcement on variables                      | 5 days | 3 days |
| Adding encryption to the specified secrets attributes            | 3 days | 2 days |
| Documentation                                                    | 4 days | -      |
  
**Total: 40 days**
