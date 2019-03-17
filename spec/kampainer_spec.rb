RSpec.describe Kampainer do
  it "has a version number" do
    expect(Kampainer::VERSION).not_to be nil
  end

  let(:username) { ENV.fetch('CAMPAIGNER_USERNAME') }
  let(:password) { ENV.fetch('CAMPAIGNER_PASSWORD') }
  subject { Kampainer::Session.new(username: username, password: password) }

  before { subject.logger = Logger.new(STDOUT) if ENV['CAMPAIGNER_LOG'] }

  it "gets a list of attributes" do
    list = subject.list_attributes

    fname_attribute = list.find { |item| item.name == 'First Name' }
    expect(fname_attribute).to be_present
    expect(fname_attribute.static_attribute_id).to eq 1
    expect(fname_attribute.is_key?).to eq false
    expect(fname_attribute.attribute_type).to eq 'Default'
    expect(fname_attribute.data_type).to eq 'String'
  end

  it "gets a list of test contacts" do
    list = subject.list_test_contacts

    contact = list.first
    expect(contact.key.id).to be_present
    expect(contact.key.unique_identifier).to be_present
    expect(contact.first_name).to be_present
    expect(contact.last_name).to be_present
    expect(contact.email).to be_present
  end

  describe "gets contacts" do
    it "fails gracefully if invalid request" do
      expect do
        subject.get_contacts
      end.to raise_error Kampainer::Error, /INVALID_CONTACT_KEYS: Invalid ContactKeys. Cannot be null/
    end

    let(:test_contacts) { subject.list_test_contacts }
    let(:test_contact) { test_contacts.sample }

    it "gets a single contact by unique identifer" do
      contacts = subject.get_contacts(unique_identifier: test_contact.email)
      contact = contacts.first

      expect(contact.key.id).to eq test_contact.key.id
      # TODO: expect(contact.email).to eq test_contact.email
    end
  end
end
