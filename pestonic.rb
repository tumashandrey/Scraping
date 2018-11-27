require 'curb'
require 'nokogiri'

class Scraping
	attr_accessor :uri, :file

	def initialize(uri = "https://www.petsonic.com/snacks-huesos-para-perros/", file = "Petsonic_CSV.csv")
		@uri = uri
		@file = file
		@curl = Curl::Easy.new
		@products = Array.new
	end

	def run
		doc = download_page(@uri)
		parsing_page(doc)
		#(2..3).each do |page|
			#doc = download_page("https://www.petsonic.com/snacks-huesos-para-perros/?p=#{page}")
			#parsing_page(doc)
		#end
		print_products
		#write_to_csv	
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

	def print_products
		@products.each do |product|
			puts "Name:  #{product[:name]}"
			puts "Price: #{product[:price]}"
			puts "Image: #{product[:img]}"
			puts "-" * 80
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

Scraping.new.run