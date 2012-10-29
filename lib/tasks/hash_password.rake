task :rehash_users => :environment do
	@users = User.all
	@users.each do | u |
		if u.username
			u.password= u.username
			u.save
			puts u.id
		end 
	end
end

