module Breeze
  module Dns

    class Zone < Veur

      desc 'create DOMAIN', 'Create a new DNS zone'
      def create(domain)
        zone = dns.zones.create(:domain => domain)
        puts "Zone ID: #{zone.id}"
        puts "Change info: #{zone.change_info}"
        puts "Name servers: #{zone.nameservers}"
        FogWrapper.flush_mock_data! if Fog.mocking?
      end

      desc 'destroy ZONE_ID', 'Destroy a DNS zone'
      def destroy(zone_id)
        zone = dns.zones.get(zone_id)
        if accept?("Destroy DNS zone and records for #{zone.domain}?")
          zone.records.each(&:destroy)
          zone.destroy
        end
      end

      desc 'import ZONE_ID FILE', 'Creates dns records specified in FILE'
      long_desc <<-END_DESC
        FILE should be the path to a ruby file that defines DNS_RECORDS like this:
        DNS_RECORDS = [
          {:name => 'example.com', :type => 'A', :ip => '1.2.3.4'},
          {:name => 'www.example.com', :type => 'CNAME', :ip => 'example.com'}
        ]
        You can also specify :ttl for each record. The default ttl is 3600 (1 hour).
      END_DESC
      def import(zone_id, file)
        load file
        zone = get_zone(zone_id)
        DNS_RECORDS.each do |record_hash|
          zone.records.create(record_hash)
          puts record_hash.inspect
        end
      end

      private

      def get_zone(id)
        dns.zones.get(id)
      end

    end

    class Record < Zone

      desc 'create ZONE_ID NAME TYPE IP [TTL]', 'Create a new DNS record'
      def create(zone_id, name, type, ip, ttl=3600)
        get_zone(zone_id).records.create(:name => name, :type => type, :value => ip, :ttl => ttl)
        FogWrapper.flush_mock_data! if Fog.mocking?
      end

      desc 'destroy ZONE_ID NAME [TYPE]', 'Destroy a DNS record'
      method_options :force => false
      def destroy(zone_id, name, type=nil)
        records = get_zone(zone_id).records.select{ |r| r.name == name && (type.nil? || r.type == type) }
        if force_or_accept?("Destroy #{records.size} record#{records.size == 1 ? '' : 's'}?")
          records.each(&:destroy)
        end
      end

    end
  end
end
