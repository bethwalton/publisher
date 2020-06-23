require "fact_check_message_processor"
require_relative "fact_check_mail"

# A class to pull messages from an email account and send relevant ones
# to a processor.
#
# It presumes that the mail class has already been configured in an
# initializer and is typically called from the mail_fetcher script
class FactCheckEmailHandler
  attr_accessor :errors, :fact_check_config

  def initialize(fact_check_config)
    @fact_check_config = fact_check_config
    self.errors = []
  end

  def process_message(message)
    message = FactCheckMail.new(message)

    return true if message.out_of_office?

    if @fact_check_config.valid_subject?(message.subject)
      edition_id = @fact_check_config.item_id_from_subject(message.subject)
      return FactCheckMessageProcessor.process(message, edition_id)
    end

    message.recipients.each do |recipient|
      if @fact_check_config.valid_address?(recipient.to_s)
        edition_id = @fact_check_config.item_id_from_address(recipient.to_s)
        return FactCheckMessageProcessor.process(message, edition_id)
      end
    end
    false
  rescue StandardError => e
    errors << "Failed to process message #{message.subject}: #{e.message}"
    GovukError.notify(e)
    false
  end

  # takes an optional block to call after processing each message
  def process
    email_count = 0
    Mail.all(read_only: false, delete_after_find: true) do |message|
      message.skip_deletion unless process_message(message)
      email_count += 1 unless message.is_marked_for_delete?
      begin
        yield(message) if block_given?
      rescue StandardError => e
        GovukError.notify(e)
      end
    end
    GovukStatsd.gauge("email.count", email_count)
  end
end
