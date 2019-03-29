// This is a template which will generate Terraform configuration file for all IAM users (eg, users.tf.json)
// Only change this template and not the generated users.tf.json

local users = import "users.json";

local source_iam_user = "terraform-aws-modules/iam/aws//modules/iam-user?ref=v0.4.0";
local source_iam_group = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies?ref=v0.4.0";

local users_fixed = [
  u + { replaced_username: std.strReplace(u.aws, ".", "_") }
  for u in std.filter(function(v) std.objectHas(v, "aws"), users)
];

{
  module: {
    [user.replaced_username]: {
      source: source_iam_user,

      name: user.aws,
      password_reset_required: false,
      force_destroy: true,
      create_iam_user_login_profile: false,
    } for user in users_fixed
  } + {
    ["developers_group"]: {
      source: source_iam_group,

      name: "developers",
      group_users: [user.aws for user in users_fixed],
      custom_group_policy_arns: ["arn:aws:iam::aws:policy/PowerUserAccess"],
    }
}
  ,
  output: {
    [user.replaced_username]: {
      value: "export AWS_ACCESS_KEY_ID=${module." + user.replaced_username + ".this_iam_access_key_id} AWS_SECRET_ACCESS_KEY=${module." + user.replaced_username + ".this_iam_access_key_secret}",
    } for user in users_fixed
  }
}
