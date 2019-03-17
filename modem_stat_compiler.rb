require 'nokogiri'
require 'mechanize'
require 'csv'

@csv = 'modem_stats.csv'
# if csv doesn't exist add the header to it
unless File.file?('modem_stats.csv')
    CSV.open(@csv, 'wb') do |csv|
        csv << %w(downstream_snr upstream_snr downstream_attn upstream_attn downstream_power upstream_power dsl_line_status dsl_uptime retrains_in_24h loss_of_power_link_failures loss_of_signal_link_failures loss_of_margin_link_failures link_train_errors unavailable_seconds near_end_crc_errors far_end_crc_errors near_end_crc_30_minute far_end_crc_30_minute near_end_fec_corrections far_end_fec_corrections near_end_fec_30_minute far_end_fec_30_minute internet_status timestamp)
    end
end

def login_to_modem
    @agent = Mechanize.new
    # Required because modem address is self signed cert
    @agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    login = @agent.get('https://192.168.0.1')
    login_form = login.forms.first
    # username field
    login_form.fields[0].value = 'admin'
    # password
    login_form.fields[2].value = 'password_on_modem'
    @agent.submit login_form
end

def get_dsl_line_status(text)
    val = text.match(/dslStatus = '(.*)'/)[1]
    case val
    when '1' then 'GOOD'
    when '2' then 'MARGINAL'
    when '3' then 'POOR'
    when '5' then 'NO FILTER DETECTED'
    else 'UNKNOWN'
    end
end

def get_dsl_status_page
    Nokogiri::HTML(@agent.get('https://192.168.0.1/modemstatus_dslstatus1.html').content)
end

def get_modem_status_page
    Nokogiri::HTML(@agent.get('https://192.168.0.1/modemstatus_connectionstatus.html').content)
end

def generate_stats
    @dsl_status_page = get_dsl_status_page
    # if our session has expired, refresh it.
    match_data = @dsl_status_page.text.match(/'.*'/)
    if match_data.to_s =~ /login/ # need to login
        login_to_modem
        @dsl_status_page = get_dsl_status_page
    end
    @modem_status_page = get_modem_status_page
    downstream_snr = @dsl_status_page.css('#DSLSNRDOWN').children.text.strip
    upstream_snr = @dsl_status_page.css('#DSLSNRUP').children.text.strip
    downstream_attn = @dsl_status_page.css('#DSLATTENDOWN').children.text.strip
    upstream_attn = @dsl_status_page.css('#DSLATTENUP').children.text.strip
    downstream_power = @dsl_status_page.css('#DSLPOWERDOWN').children.text.strip
    upstream_power = @dsl_status_page.css('#DSLPOWERUP').children.text.strip
    dsl_line_status = get_dsl_line_status(@dsl_status_page.css('#LINESTATUS').text)
    dsl_uptime = @dsl_status_page.css('#DSLUPTIME').text
    retrains_in_24h = @dsl_status_page.css('#RETRAINS24HR').to_s.match(/RetrainCurr24H = '(.*)'/)[1]
    loss_of_power_link_failures = @dsl_status_page.css('#linkFailLPR').text
    loss_of_signal_link_failures = @dsl_status_page.css('#linkFailLOS').text
    loss_of_margin_link_failures = @dsl_status_page.css('#linkFailLOM').text
    link_train_errors = @dsl_status_page.css('#linkTrainErr').text
    unavailable_seconds = @dsl_status_page.css('#DSLUAS').text
    near_end_crc_errors = @dsl_status_page.css('#CRC_NEAR').text
    far_end_crc_errors = @dsl_status_page.css('#CRC_FAR').text
    near_end_crc_30_minute = @dsl_status_page.css('#CRC_NEAR30M').text
    far_end_crc_30_minute = @dsl_status_page.css('#CRC_FAR30M').text
    near_end_fec_corrections = @dsl_status_page.css('#FEC_NEAR').text
    far_end_fec_corrections = @dsl_status_page.css('#FEC_FAR').text
    near_end_fec_30_minute = @dsl_status_page.css('#FEC_NEAR30M').text
    far_end_fec_30_minute = @dsl_status_page.css('#FEC_FAR30M').text
    
    # a lot of useful data here
    allStatus = @modem_status_page.text.match(/allStatus = \"(.*)\"/)[1].split('||')
    internet_status = allStatus[2]


    puts "downstream_snr: #{downstream_snr}"
    puts "upstream_snr: #{upstream_snr}"
    puts "downstream_attn: #{downstream_attn}"
    puts "upstream_attn: #{upstream_attn}"
    puts "downstream_power: #{downstream_power}"
    puts "upstream_power: #{upstream_power}"
    puts "dsl_line_status: #{dsl_line_status}"
    puts "dsl_uptime: #{dsl_uptime}"
    puts "retrains_in_24h: #{retrains_in_24h}"
    puts "loss_of_power_link_failures: #{loss_of_power_link_failures}"
    puts "loss_of_signal_link_failures: #{loss_of_signal_link_failures}"
    puts "loss_of_margin_link_failures: #{loss_of_margin_link_failures}"
    puts "link_train_errors: #{link_train_errors}"
    puts "unavailable_seconds: #{unavailable_seconds}"
    puts "near_end_crc_errors: #{near_end_crc_errors}"
    puts "far_end_crc_errors: #{far_end_crc_errors}"
    puts "near_end_crc_30_minute: #{near_end_crc_30_minute}"
    puts "far_end_crc_30_minute: #{far_end_crc_30_minute}"
    puts "near_end_fec_corrections: #{near_end_fec_corrections}"
    puts "far_end_fec_corrections: #{far_end_fec_corrections}"
    puts "near_end_fec_30_minute: #{near_end_fec_30_minute}"
    puts "far_end_fec_30_minute: #{far_end_fec_30_minute}"
    puts "internet_status: #{internet_status}"
    puts "time_stamp: #{Time.now.to_s}"

    CSV.open(@csv, 'a+') do |csv|
        csv << [downstream_snr,upstream_snr,downstream_attn,upstream_attn,downstream_power,upstream_power,dsl_line_status,dsl_uptime,retrains_in_24h,loss_of_power_link_failures,loss_of_signal_link_failures,loss_of_margin_link_failures,link_train_errors,unavailable_seconds,near_end_crc_errors,far_end_crc_errors,near_end_crc_30_minute,far_end_crc_30_minute,near_end_fec_corrections,far_end_fec_corrections,near_end_fec_30_minute,far_end_fec_30_minute,internet_status,Time.now.to_s]
    end

end

login_to_modem
generate_stats

while (true)
    sleep(10)
    generate_stats
end