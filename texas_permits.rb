require 'rails'
require 'nokogiri'
require 'watir'
require 'csv'

CSV.open('permits.csv', 'wb') do |csv|
  csv << ["Lease", "Well Number", "Permitted Operator", "County", "Status Date", "Status Number", "Wellbore Profiles", "Filing Purpose", "Amend", "Total Depth", "Stacked Lateral Parent Well DP#", "Status"]
end

browser = Watir::Browser.new(:chrome)
browser.goto("http://webapps2.rrc.state.tx.us/EWA/drillingPermitsQueryAction.do")
last_week = 1.week.ago.strftime("%m/%d/%Y")
browser.input(name: 'searchArgs.submittedDtFromHndlr.inputValue').send_keys(last_week)
browser.button(type: 'submit').click
sleep 1
browser.select(name: 'pager.pageSize').send_keys('View All')
sleep 1
permit_list_page = Nokogiri::HTML.parse(browser.html)
permit_table = permit_list_page.css("table").sort { |x,y| y.css("tr").count <=> x.css("tr").count }.first
rows = permit_table.css('tr')
rows = rows.select { |row| !row.at_css('td:nth-child(5)').nil? }
rows = rows.select { |row| (row.css('td').count == 14) || (row.css('td').count == 16) }

CSV.open('permits.csv', 'a+') do |csv|
  rows.each do |row|
    row_array = []
    i = 3
    until i > 14
      row_array.push(row.at_css("td:nth-child(#{i})").text.squish)
      i += 1
    end
    csv << row_array
    i = 3
  end
end

operator_counts = Hash.new{ |operator_counts, k| operator_counts[k] = [] }
rows.each do |row|
  operator_counts["#{row.at_css('td:nth-child(5)').text.squish}"] << "#{row.at_css('td:nth-child(3)').text.squish} #{row.at_css('td:nth-child(4)').text.squish}"
end

CSV.open('counts.csv', 'wb') do |csv|
  csv << ["Operator", "Permits filed"]
end

CSV.open('counts.csv', 'a+') do |csv|
  operator_counts.each do |k, v|
    csv << ["#{k}", "#{v.count}"]
  end
end
