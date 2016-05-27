require 'pdf-reader'
class Reader < PDF::Reader
	def get_text
		page_text = ''

		pages.each do |page|
			page_text << page.text
		end

		page_text.gsub(/^$\n/, '')
	end
end
