terraform {
  backend "s3" {
    bucket         = "shivamjtestbucket"    # Replace with your bucket name
    key            = "Terra-state/mystate2"  # Adjust the path
    region         = "ap-south-1"            # e.g., "us-east-1"
    dynamodb_table = "terra-DB"    # Optional, for state locking
    encrypt        = true                     # Enable encryption
  }
}
