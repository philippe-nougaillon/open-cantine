class Blog < ActiveRecord::Base

  attr_accessible :titre, :texte  

  def self.search(page)
	paginate :per_page => 5, :page => page, :order => "updated_at DESC"
  end

end
