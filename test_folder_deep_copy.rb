# Copyright 2002-2013 Rally Software Development Corp. All Rights Reserved.
#
# This script is open source and is provided on an as-is basis. Rally provides
# no official support for nor guarantee of the functionality, usability, or
# effectiveness of this code, nor its suitability for any application that
# an end-user might have in mind. Use at your own risk: user assumes any and
# all risk associated with use and implementation of this script in his or
# her own environment.

# Usage: ruby test_folder_deep_copy.rb
# Specify the User-Defined variables below. Script will copy an entire
# Test Folder hierarchy, including child Folders, Test Cases, and their
# Test Steps and Attachments and Tags, to a new Test Folder hierarchy that
# the script will create. The target hierarchy can reside in a different project.

# Note: script does not copy TestCaseResults, assuming that the target hierarchy
# will be starting "fresh" from a testing perspective

require 'rally_api'

$my_base_url       = "https://rally1.rallydev.com/slm"
$my_username       = "user@company.com"
$my_password       = "password"
$my_workspace      = "My Workspace"
$my_project        = "My Project"
$wsapi_version     = "1.40"

# Target project (can be same as source project)
$target_project_name    = "My Project"

# Source Test Folder
$source_test_folder_formatted_id = "TF5"

# Make no edits below this line!!
# =================================

#Setting custom headers
$headers                            = RallyAPI::CustomHttpHeader.new()
$headers.name                       = "Test Folder Deep Copy"
$headers.vendor                     = "Rally Labs"
$headers.version                    = "0.50"

# Load (and maybe override with) my personal/private variables from a file...
my_vars= File.dirname(__FILE__) + "/my_vars.rb"
if FileTest.exist?( my_vars ) then require my_vars end

def copy_test_steps(source_test_case, target_test_case)

  source_test_case_steps = source_test_case["Steps"]

  source_test_case_steps.each do |source_test_case_step|
    full_source_step = source_test_case_step.read
    target_step_fields = {}
    target_step_fields["TestCase"] = target_test_case
    target_step_fields["StepIndex"] = full_source_step["StepIndex"]
    target_step_fields["Input"] = full_source_step["Input"]
    target_step_fields["ExpectedResult"] = full_source_step["ExpectedResult"]
    begin
      target_test_case_step = @rally.create(:testcasestep, target_step_fields)
      puts "===> Copied TestCaseStep: #{target_test_case_step["_ref"]}"
    rescue => ex
      puts "Test Case Step not copied due to error:"
      puts ex
    end
  end

end

def copy_attachments(source_test_case, target_test_case)
  source_attachments = source_test_case["Attachments"]

  source_attachments.each do |source_attachment|
    full_source_attachment = source_attachment.read
    source_attachment_content = full_source_attachment["Content"]
    full_source_attachment_content = source_attachment_content.read

    # Create AttachmentContent Object for Target
    target_attachment_content_fields = {}
    target_attachment_content_fields["Content"] = full_source_attachment_content["Content"]
    begin
      target_attachment_content = @rally.create(:attachmentcontent, target_attachment_content_fields)
      puts "===> Copied AttachmentContent: #{target_attachment_content["_ref"]}"
    rescue => ex
      puts "AttachmentContent not copied due to error:"
      puts ex
    end

    # Now Create Attachment Container
    target_attachment_fields = {}
    target_attachment_fields["Name"] = full_source_attachment["Name"]
    target_attachment_fields["Description"] = full_source_attachment["Description"]
    target_attachment_fields["Content"] = target_attachment_content
    target_attachment_fields["ContentType"] = full_source_attachment["ContentType"]
    target_attachment_fields["Size"] = full_source_attachment["Size"]
    target_attachment_fields["Artifact"] = target_test_case
    target_attachment_fields["User"] = full_source_attachment["User"]
    begin
      target_attachment = @rally.create(:attachment, target_attachment_fields)
      puts "===> Copied Attachment: #{target_attachment["_ref"]}"
    rescue => ex
      puts "Attachment not copied due to error:"
      puts ex
    end
  end
end

def get_test_case_fields(source_test_case, target_project, target_test_folder)

  # Check if there's an Owner
  if !source_test_case["Owner"].nil?
    source_owner = source_test_case["Owner"]
  else
    source_owner = nil
  end

  # Populate field data from Source to Target
  target_fields = {}
  target_fields["Package"] = source_test_case["Package"]
  target_fields["Description"] = source_test_case["Description"]
  target_fields["Method"] = source_test_case["Method"]
  target_fields["Name"] = source_test_case["Name"]
  target_fields["Objective"] = source_test_case["Objective"]
  target_fields["Owner"] = source_owner
  target_fields["PostConditions"] = source_test_case["PostConditions"]
  target_fields["PreConditions"] = source_test_case["PreConditions"]
  target_fields["Priority"] = source_test_case["Priority"]
  target_fields["Project"] = target_project
  target_fields["Risk"] = source_test_case["Risk"]
  target_fields["ValidationInput"] = source_test_case["ValidationInput"]
  target_fields["ValidationExpectedResult"] = source_test_case["ValidationExpectedResult"]
  target_fields["Tags"] = source_test_case["Tags"]
  target_fields["TestFolder"] = target_test_folder

  return target_fields

end

def copy_test_folder(source_test_folder, target_project, parent_of_target_folder)

  # Create Target Test Folder
  target_test_folder_fields = {}

  # Only prepend "(Copy of)" for top-level Test Folder
  if parent_of_target_folder == nil then
    target_test_folder_fields["Name"] = "(Copy of) " + source_test_folder["Name"]

  # Only set parent folder if we have a parent
  else
    target_test_folder_fields["Name"]    = source_test_folder["Name"]
    target_test_folder_fields["Parent"]  = parent_of_target_folder
  end

  target_test_folder_fields["Project"]   = target_project

  # Finally call Rally to Create Target Test Folder
  target_test_folder = @rally.create(:testfolder, target_test_folder_fields)
  target_test_folder.read

  if parent_of_target_folder == nil then
    puts "Created new top-level Test Folder: " + target_test_folder["FormattedID"] + ": " + target_test_folder["Name"]
  else
    puts "Created new child Test Folder: " + target_test_folder["FormattedID"] + ": " + target_test_folder["Name"]
  end

  # Grab collection of Source Test Cases
  source_test_cases = source_test_folder["TestCases"]

  # Loop through Source Test Cases and Copy to Target
  source_test_cases.each do |source_test_case|

    # Get full object for Source Test Case
    full_source_test_case = source_test_case.read

    # Populate data field values of target test case
    target_test_case_fields = get_test_case_fields(full_source_test_case, target_project, target_test_folder)

    # Create the Target Test Case
    begin
      target_test_case = @rally.create(:testcase, target_test_case_fields)
      puts "Test Case: #{full_source_test_case["FormattedID"]} successfully copied to #{target_test_folder["FormattedID"]}"
    rescue => ex
      puts "Test Case: #{full_source_test_case["FormattedID"]} not copied due to error"
      puts ex
    end

    # Now Copy Test Steps
    copy_test_steps(full_source_test_case, target_test_case)

    # Now Copy Attachments
    copy_attachments(full_source_test_case, target_test_case)
  end

  # Proceed on to child Test Folders, if applicable
  child_folders = source_test_folder["Children"]

  # Loop through children and call self recursively to walk folder tree and copy fully
  unless child_folders.nil? then
    child_folders.each do | this_child_folder |
      this_child_folder.read
      copy_test_folder(this_child_folder, target_project, target_test_folder)
    end
  end
end

begin

  #==================== Make a connection to Rally ====================

  config                  = {:base_url => $my_base_url}
  config[:username]       = $my_username
  config[:password]       = $my_password
  config[:workspace]      = $my_workspace
  config[:project]        = $my_project
  config[:version]        = $wsapi_version
  config[:headers]        = $headers

  @rally = RallyAPI::RallyRestJson.new(config)

  # Lookup source Test Folder
  source_test_folder_query = RallyAPI::RallyQuery.new()
  source_test_folder_query.type = :testfolder
  source_test_folder_query.fetch = true
  source_test_folder_query.query_string = "(FormattedID = \"" + $source_test_folder_formatted_id + "\")"

  source_test_folder_result = @rally.find(source_test_folder_query)

  if source_test_folder_result.total_result_count == 0
    puts "Source Test Folder: " + $source_test_folder_formatted_id + " not found. Exiting."
    exit
  end

  source_test_folder = source_test_folder_result.first()

  # Lookup Target Project
  target_project_query = RallyAPI::RallyQuery.new()
  target_project_query.type = :project
  target_project_query.fetch = true
  target_project_query.query_string = "(Name = \"" + $target_project_name + "\")"

  target_project_result = @rally.find(target_project_query)

  if target_project_result.total_result_count == 0
    puts "Target Project: " + $target_project_name + " not found. Exiting."
    exit
  end

  target_project = target_project_result.first()
  copy_test_folder(source_test_folder, target_project, nil)

end