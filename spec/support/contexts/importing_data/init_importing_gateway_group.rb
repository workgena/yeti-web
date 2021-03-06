# frozen_string_literal: true

shared_context :init_importing_gateway_group do |args|
  args ||= {}

  before do
    fields = {
      name: 'GWGroup',
      vendor_id: @contractor.id,
      vendor_name: @contractor.name
    }.merge(args)

    @importing_gateway_group = FactoryGirl.create(:importing_gateway_group, fields)
  end
end
