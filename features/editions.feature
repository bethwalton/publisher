Feature: Managing editions
  In order to publish content
  As an editor
  I want to be able to create, assign, review, fact check and publish editions

  Background:
    Given I am signed in to Publisher

  Scenario: Create an edition
    Given I have an artefact in Panopticon
      And I have clicked the create publication button in Panopticon
    When I am redirected to Publisher
    Then a new edition should be created
      And the edition form should show the fields

  Scenario: View editions
    Given lined up editions exist in Publisher
    When I visit the editions list
      And filter by everyone
      And select the lined up tab
    Then I should see each lined up edition in the list

  Scenario: Edit edition
    Given draft editions exist in Publisher
    When I update fields for an edition
    Then the edition form should show the fields