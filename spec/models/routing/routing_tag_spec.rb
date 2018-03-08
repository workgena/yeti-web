# == Schema Information
#
# Table name: class4.routing_tags
#
#  id   :integer          not null, primary key
#  name :string           not null
#

require 'spec_helper'

RSpec.describe Routing::RoutingTag, type: :model do

  context '#destroy' do
    let(:tag) do
      create(:routing_tag)
    end

    let(:tag_values) do
      # put subject tag is in the middle, to make test more extensive
      [create(:routing_tag).id, tag.id, create(:routing_tag).id]
    end

    subject do
      tag.destroy!
    end

    shared_examples :tag_can_not_be_destoryed do
      it 'should raise error' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotDestroyed)
      end

      it 'tag is not destoryed' do
        expect {
          subject rescue true
        }.not_to change { described_class.count }
      end
    end

    context 'when Tag was not used in any other resources' do
      it 'destroy tag successfully' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when Tag has CustomersAuth' do
      before do
        create(:customers_auth, tag_action_value: tag_values)
      end

      include_examples :tag_can_not_be_destoryed
    end

    context 'when Tag has Numberlist' do
      before do
        create(:numberlist, tag_action_value: tag_values)
      end

      include_examples :tag_can_not_be_destoryed
    end

    context 'when Tag has NumberlistItem' do
      before do
        create(:numberlist_item, tag_action_value: tag_values)
      end

      include_examples :tag_can_not_be_destoryed
    end

    context 'when Tag has RoutingTagDetectionRule' do
      before do
        create(:routing_tag_detection_rule,
               tag_action_value: tag_values)
      end

      include_examples :tag_can_not_be_destoryed
    end

    context 'when Tag has Dialpeer' do
      before do
        create(:dialpeer, routing_tag_ids: tag_values)
      end

      include_examples :tag_can_not_be_destoryed
    end

    context 'when Tag has Destination' do
      before do
        create(:destination, routing_tag_ids: tag_values)
      end

      include_examples :tag_can_not_be_destoryed
    end
  end

end
