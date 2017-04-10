module Grape
  module DSL
    module Headers
      # Set an individual header or retrieve
      # all headers that have been set.
      def header(key = nil, val = nil)
        if key
          val ? header[key.to_s] = val : header.delete(key.to_s)
        else
          @header ||= {}
        end
      end
      alias headers header

      def use(*names)
        named_headers = @api.namespace_stackable_with_hash(:named_headers) || {}
        options = names.extract_options!
        names.each do |name|
          params_block = named_headers.fetch(name) do
            raise "Headers :#{name} not found!"
          end
          instance_exec(options, &params_block)
        end
      end
      alias use_scope use
      alias includes use

      def requires(*attrs, &block)
        opts = attrs.extract_options!.clone
        opts[:presence] = { value: true, message: opts[:message] }
        opts = @group.merge(opts) if @group

        if opts[:using]
          require_required_and_optional_fields(attrs.first, opts)
        else
          validate_attributes(attrs, opts, &block)

          push_declared_params(attrs)
        end
      end

      def optional(*attrs, &block)
        opts = attrs.extract_options!.clone
        opts = @group.merge(opts) if @group

        if opts[:using]
          require_optional_fields(attrs.first, opts)
        else
          validate_attributes(attrs, opts, &block)

          push_declared_params(attrs)
        end
      end

      def with(*attrs, &block)
        new_group_scope(attrs.clone, &block)
      end

      def mutually_exclusive(*attrs)
        validates(attrs, mutual_exclusion: { value: true, message: extract_message_option(attrs) })
      end

      def exactly_one_of(*attrs)
        validates(attrs, exactly_one_of: { value: true, message: extract_message_option(attrs) })
      end

      def at_least_one_of(*attrs)
        validates(attrs, at_least_one_of: { value: true, message: extract_message_option(attrs) })
      end

      def all_or_none_of(*attrs)
        validates(attrs, all_or_none_of: { value: true, message: extract_message_option(attrs) })
      end

      def given(*attrs, &block)
        attrs.each do |attr|
          proxy_attr = attr.is_a?(Hash) ? attr.keys[0] : attr
          raise Grape::Exceptions::UnknownParameter.new(proxy_attr) unless declared_header?(proxy_attr)
        end
        new_lateral_scope(dependent_on: attrs, &block)
      end

      def declared_header?(header)
        @declared_headers.flatten.include?(header)
      end

      alias group requires

      def params(params)
        params
      end
    end
  end
end
