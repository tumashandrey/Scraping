#url = "https://www.petsonic.com/snacks-huesos-para-perros/"
#ruby pestonic.rb "https://www.petsonic.com/snacks-huesos-para-perros/" file_name.csv

require 'curb'
require 'nokogiri'
require 'csv'

class Scraping

	attr_accessor :uri, :file

	def initialize(uri, file)

		@uri = uri
		@file = file
		puts "Scraping url, #{@uri}"
		@curl = Curl::Easy.new do |curl|
			curl.headers["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36"
			curl.headers["Accept-Language"] = "ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7"
			curl.enable_cookies = true
		end

		@products = Array.new

	end

	def run

		doc = download_page(@uri)
		puts "Download: #{@uri}"
		puts "We build Nokogiri..."
		puts "Max pages: #{get_max_page(doc)}"
		puts "Parsing page 1"
		parsing_page(doc)
		
		(2..get_max_page(doc)).each do |page|
			puts "Parsing page #{page}"
			doc = download_page("#{@uri}?p=#{page}")
			parsing_page(doc)
		end

		puts "-" * 80
		puts "Number products: #{@products.size}"
		write_to_csv
		puts "Add result file #{@file}"


	end

	def download_page(url)

		@curl.url = url
		@curl.perform
		Nokogiri::HTML(@curl.body_str)

	end

	def get_max_page(doc)
		
		doc.xpath("(//ul[contains(@class,'pagination')]/li)[last()-1]").text.to_i
	end

	def parsing_page(doc)

		doc.xpath("//ul[@id='product_list']/li[contains(@class,'ajax_block_product')]//h2/a/@href").each do |product_link|

			page = download_page(product_link)
			product_name = page.xpath("//h1[@itemprop='name']/text()").text.strip
			page.xpath(".//ul[contains(@class,'attribute_radio_list')]/li").each do |weighting|

				product = Hash.new

				weightings_name = weighting.xpath(".//span[@class='radio_label']").text.strip

				product[:name] = product_name + " - " + weightings_name
				product[:price] = weighting.xpath(".//span[@class='price_comb']").text[/([.,\d]+)/].strip
				product[:image] = page.xpath(".//img[@id='bigpic']/@src").text.strip

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

Scraping.new(ARGV[0],ARGV[1]).run
