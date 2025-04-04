module Trestle
  module ActiveStorage
    module ControllerConcern
      extend ActiveSupport::Concern

      included do
        before_action :define_attachment_accessors, only: [:show, :edit, :update, :destroy]
        after_action :purge_attachments, only: [:update]
      end

      private

      def define_attachment_accessors
        load_instance

        admin.active_storage_fields.each do |field|
          instance, field = instance_field(field)
          attachment = instance.send(field)

            if attachment.respond_to?(:each)
              attachment.each do |att|
                instance.class.send(:attr_accessor, "delete_#{field}_#{att.blob_id.to_s.gsub('-', '')}")
              end
            else
              instance.class.send(:attr_accessor, "delete_#{field}")
            end
          end
        end

      def instance_field(field)
        case field
        when String, Symbol
          [instance, field]
        when Array
          inst, field = field
          [instance.send(inst), field]
        when Hash
          inst, field = field.first
          [instance.send(inst), field]
        end
      end

      def purge_attachments
        admin.active_storage_fields.each do |field|
          instance, field = instance_field(field)
          attachment = instance.send(field)

          if attachment.respond_to?(:each)
            attachment.each do |att|
              att.purge if instance.try("delete_#{field}_#{att.blob_id.to_s.gsub('-', '')}") == '1'
            end
          else
            instance.send(field).purge if instance.try("delete_#{field}") == '1'
          end
        end
      end
    end
  end
end
