Rally-TestFolder-DeepCopy
=========================

Usage: ruby test_folder_deep_copy.rb

Edit / update the following variables located in my_vars.rb to suit your environment:

<pre>
$my_base_url                     = "https://rally1.rallydev.com/slm"
$my_username                     = "user@company.com"
$my_password                     = "topsecret"
$wsapi_version                   = "1.40"
$my_workspace                    = "My Workspace"
$my_project                      = "My Project 1"

# Target project: (can be same as source)
$target_project_name             = "My Project 2"

# Source Test Folder
$source_test_folder_formatted_id = "TF5"
</pre>

Specify the User-Defined variables below. Script will copy an entire
Test Folder hierarchy, including child Folders, Test Cases, and their
Test Steps and Attachments and Tags, to a new Test Folder hierarchy that
the script will create. The target hierarchy can reside in a different project.