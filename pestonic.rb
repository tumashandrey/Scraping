#url = "https://www.petsonic.com/snacks-huesos-para-perros/"
#ruby pestonic "https://www.petsonic.com/snacks-huesos-para-perros/" file.csv
require 'curb'
require 'nokogiri'
require 'csv'

class Scraping

	attr_accessor :uri, :file

	def initialize(uri = ARGV[0], file = ARGV[1])

		puts "Scraping, #{ARGV[0]}"
		@uri = uri
		@file = file
		@curl = Curl::Easy.new do |curl|
			curl.headers["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36"
			curl.headers["Accept-Language"] = "ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7"
		end
		@products = Array.new

	end

	def run

		doc = download_page(@uri)
		puts "Download: #{ARGV[0]}"
		puts "We build Nokogiri..."
		puts "Parsing page 1"
		parsing_page(doc)
		(2..10).each do |page|
			puts "Parsing page #{page}"
			doc = download_page("#{ARGV[0]}?p=#{page}")
			parsing_page(doc)
		end
		puts "-" * 80
		puts "Number products: #{@products.size}"
		puts "Add result file #{ARGV[1]}"
		write_to_csv

	end

	def download_page(url)

		@curl.url = url
		@curl.perform
		
		Nokogiri::HTML(@curl.body_str)

	end

	def parsing_page(doc)

		doc.xpath("//ul[@id='product_list']/li[contains(@class,'ajax_block_product')]//h2/a/@href").each do |product_link|

			page = download_page(product_link)
			product_name = page.xpath("//h1[@itemprop='name']/text()").text
			page.xpath(".//ul[contains(@class,'attribute_radio_list')]/li").each do |weighting|
				
				product = Hash.new

				weightings_name = weighting.xpath(".//span[@class='radio_label']").text

				product[:name] = product_name + " - " + weightings_name
				product[:price] = weighting.xpath(".//span[@class='price_comb']").text[/(\d+[.,\d]\d+)/]
				product[:img] = page.xpath(".//img[@id='bigpic']/@src").text

				@products << product

			end
		end
	end

	def write_to_csv

		CSV.open(@file, "w", write_headers: true, headers: @products.last.keys) do |csv|
			@products.each do |product|
				csv << product.values	
			end
		end	
	end

end

if ARGV.empty?

	puts "ruby pestonic.rb a b. Please, pass the parameters to the script a: link to the category page (any category of the site can be transmitted),
	b: the name of the file in which the result will be written"

end

Scraping.new.run