require 'rubygems'
require 'nokogiri'
require 'open-uri'

def scrape_url
  File.readlines('sample-urls.txt').each do |line|
    url = line.strip
    p "--> #{url}"
    begin
      Nokogiri::HTML(open(url, redirect: false))
    rescue OpenURI::HTTPError, OpenURI::HTTPRedirect, SocketError, Timeout::Error, Errno::ECONNREFUSED
      next
    end
    links = extract_links(url)
    find_other_pages(links, url)
    find_twitter_github(links)
  end
end

def extract_links(url)
  Nokogiri::HTML(open(url)).css("a[href]")
end

def find_other_pages(links, url)
  links.each do |link|
    if link['href'].include?(url)
       links += extract_links(link['href'])
    end
  end
end

def find_twitter_github(links)
  links.each do |link|
    if link["href"] =~ /((http|https):\/\/)?(github\.com\/[a-z0-9](?:-?[a-z0-9]){0,38}[\/]?)$/i
      p github = link['href']
    end
    if link["href"] =~ /((http|https):\/\/)?(twitter\.com\/[a-z0-9](?:-?[a-z0-9]){0,38}[\/]?)$/i
      p twitter = link['href']
    end
  end
end

scrape_url

require 'github_api'
results = []

response = Github.repos.list(user: 'yggie')
response.each_page do |page|
  results << page.max { |a,b| a[:stargazers_count] <=> b[:stargazers_count] }
end

p results.max { |a,b| a[:stargazers_count] <=> b[:stargazers_count] }.name
