# encoding: utf-8

class NoisyWorkflow < ActionMailer::Base
  default :from => "Winston (GOV.UK Publisher) <winston@alphagov.co.uk>"

  EMAIL_GROUPS = {
    :team => 'govuk-team@digital.cabinet-office.gov.uk',
    :dev => 'govuk-dev@digital.cabinet-office.gov.uk',
    :franchise_editors => 'freds@alphagov.co.uk',
    :editors => 'govuk-content-designers@digital.cabinet-office.gov.uk',
    :business => 'publisher-alerts-business@digital.cabinet-office.gov.uk',
  }

  def make_noise(action)
    @action = action

    if action.edition.business_proposition
      subject = "[PUBLISHER]-BUSINESS #{@action.friendly_description}"
    else
      subject = "[PUBLISHER] #{@action.friendly_description}"
    end

    recipient_emails = []
    if Plek.current.environment == 'preview'
      recipient_emails << EMAIL_GROUPS[:dev]
    else
      if action.edition.business_proposition
        recipient_emails << EMAIL_GROUPS[:business]
        if action.request_type == Action::PUBLISH
          recipient_emails << EMAIL_GROUPS[:team]
        end
      else
        recipient_emails << EMAIL_GROUPS[:franchise_editors]
        if action.request_type == Action::PUBLISH
          recipient_emails << EMAIL_GROUPS[:team]
        else
          recipient_emails << EMAIL_GROUPS[:editors]
        end
      end
    end

    mail(:to => recipient_emails.join(', '),
         :subject => subject)
  end

  def request_fact_check(action)
    @edition = action.edition
    fact_check_address = @edition.fact_check_email_address
    mail(:to => action.email_addresses, :reply_to => fact_check_address,
      :from => "Beta Editorial Team <#{fact_check_address}>",
      :subject => "[FACT CHECK REQUESTED] #{@edition.title}") do |format|
     format.text { render :text => action.customised_message }
   end

  end

  def report_errors(error_list)
    @errors = error_list
    mail(:to => EMAIL_GROUPS['dev'], :subject => 'Errors in fact check email processing')
  end

end
