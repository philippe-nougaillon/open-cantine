class Paiement < ActiveRecord::Base

  attr_protected :id

  belongs_to :famille
  belongs_to :ville

  validates_presence_of :date,:montant, :montantGarderie, :montantCantine, :famille_id
  
  def self.search(search, page, mairie_id, famille_id, sort)

     if famille_id
        conditions = ['ref like ? AND familles.mairie_id = ? AND famille_id = ?', "%#{search}%", mairie_id, famille_id]
     else
        conditions = ['ref like ? AND familles.mairie_id = ? ', "%#{search}%", mairie_id]
     end
	
	 @order_by = (sort.blank?) ? "id DESC" : sort	

	 paginate :per_page => 18,
              :page => page,
              :conditions => conditions,
              :joins => :famille,
              :order => @order_by
  end

  def self.to_csv
    CSV.generate do |csv|
      csv << column_names
      all.each do |p|
        csv << p.attributes.values_at(*column_names)
      end
    end
  end
  
end
