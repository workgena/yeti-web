# frozen_string_literal: true

# == Schema Information
#
# Table name: cdr_exports
#
#  id           :integer          not null, primary key
#  status       :string           not null
#  fields       :string           default([]), not null, is an Array
#  filters      :json             not null
#  callback_url :string
#  type         :string           not null
#  created_at   :datetime
#  updated_at   :datetime
#  rows_count   :integer
#

class CdrExport < Yeti::ActiveRecord
  self.table_name = 'cdr_exports'
  self.store_full_sti_class = false

  STATUS_PENDING = 'Pending'
  STATUS_COMPLETED = 'Completed'
  STATUS_FAILED = 'Failed'
  STATUS_DELETED = 'Deleted'
  STATUSES = [
    STATUS_PENDING,
    STATUS_COMPLETED,
    STATUS_FAILED,
    STATUS_DELETED
  ].freeze

  # need for activeadmin form
  attr_accessor :customer_acc_id_eq,
                :is_last_cdr_eq, :time_start_gteq, :time_start_lteq

  validates_presence_of :status, :fields, :filters
  validate do
    if filters['time_start_gteq'].empty? || filters['time_start_lteq'].empty?
      errors.add(:filters, 'requires time_start_lteq & time_start_gteq')
    end
  end
  validate do
    extra_fields = fields - self.class.allowed_fields
    if extra_fields.any?
      errors.add(:fields, "#{extra_fields.join(', ')} not allowed")
    end
    extra_filters = filters.keys - self.class.allowed_filters
    if extra_filters.any?
      errors.add(:filters, "#{extra_filters.join(', ')} not allowed")
    end
  end

  def fields=(f)
    self[:fields] = f.map(&:presence).compact
  end

  before_validation(on: :create) do
    self.status ||= STATUS_PENDING
    self.type ||= 'Base'
  end

  after_create do
    # dj which exports CDRs into CSV
    Worker::CdrExportJob.perform_later(id)
  end

  after_update if: proc { saved_change_to_attribute?(:status) && deleted? } do
    Worker::RemoveCdrExportFileJob.perform_later(id)
  end

  alias_attribute :export_type, :type

  def export_sql
    Cdr::Cdr.select(fields.join(', ')).order('time_start desc').ransack(filters).result.to_sql
  end

  def completed?
    status == STATUS_COMPLETED
  end

  def deleted?
    status == STATUS_DELETED
  end

  def self.allowed_filters
    %w[
      time_start_lteq
      time_start_gteq
      success_eq
      customer_auth_external_id_eq
      failed_resource_type_id_eq
      src_prefix_in_contains
      dst_prefix_in_contains
      src_prefix_routing_contains
      dst_prefix_routing_contains
      customer_acc_external_id_eq
      is_last_cdr_eq
      customer_acc_id_eq
    ]
  end

  # any cdr columns
  def self.allowed_fields
    Cdr::Cdr.column_names
  end
end
