class Blog < ApplicationRecord

  def self.search(page)
	paginate(per_page:4, page:page).order("updated_at DESC")
  end

end
