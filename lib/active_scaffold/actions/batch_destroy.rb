module ActiveScaffold::Actions
  module BatchDestroy

    def self.included(base)
      base.before_filter :batch_destroy_authorized_filter, :only => [:batch_destroy]
    end

    def batch_destroy
      batch_action
    end
    
    protected

    def batch_destroy_listed
      case active_scaffold_config.batch_destroy.process_mode
      when :delete then
        each_record_in_scope {|record| batch_destroy_record(record)}
      when :delete_all then
        do_search if respond_to? :do_search
        active_scaffold_config.model.delete_all(all_conditions)
      end
      
    end

    def batch_destroy_marked
      case active_scaffold_config.batch_destroy.process_mode
      when :delete then
        active_scaffold_config.model.marked.each {|record| batch_destroy_record(record)}
      when :delete_all then
        active_scaffold_config.model.marked.delete_all
        do_demark_all
      end
    end

    def batch_destroy_record(record)
      if record.authorized_for?(:crud_type => :delete)
        destroy_record(record)
      else
        record.errors.add(:base, as_(:no_authorization_for_action, :action => action_name))
        error_records << record
      end
    end

    def destroy_record(record)
      @successful = nil
      @record = record

      do_destroy
      if successful?
        @record.marked = false if batch_scope == 'MARKED'
      else
        error_records << @record
      end
    end

    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def batch_destroy_authorized?(record = nil)
      authorized_for?(:crud_type => :delete)
    end

    private

    def batch_destroy_authorized_filter
      link = active_scaffold_config.batch_destroy.link || active_scaffold_config.batch_destroy.class.link
      raise ActiveScaffold::ActionNotAllowed unless self.send(link.first.security_method)
    end
  end
end
