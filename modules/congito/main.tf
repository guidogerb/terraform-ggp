resource "aws_cognito_user_pool" "cognito_user_pool" {
  name = "cognito-user-pool"

  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  auto_verified_attributes = ["email"]

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = false
  }
}

resource "aws_cognito_user_pool_client" "cognito_user_pool_client" {
  name                = "ggp-app-client"
  user_pool_id        = aws_cognito_user_pool.cognito_user_pool.id
  generate_secret     = false
  allowed_oauth_flows = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = ["phone", "email", "openid", "profile"]
  callback_urls       = ["https://guidogerbpublishing.com/callback"]
  logout_urls         = ["https://guidogerbpublishing.com/logout"]
  supported_identity_providers = ["COGNITO"]
}

resource "aws_cognito_identity_pool" "cognito_identity_pool" {
  identity_pool_name               = "ggp-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    provider_name = aws_cognito_user_pool.cognito_user_pool.endpoint
    client_id     = aws_cognito_user_pool_client.cognito_user_pool_client.id
  }
}

resource "aws_iam_role" "authenticated" {
  name = "cognito-authenticated-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.cognito_identity_pool.id
          }
        }
      }
    ]
  })
}

# Adding a minimal inline policy
resource "aws_iam_role_policy" "authenticated_policy" {
  name   = "authenticated-policy"
  role   = aws_iam_role.authenticated.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [] # Empty policy with no permissions
  })
}
