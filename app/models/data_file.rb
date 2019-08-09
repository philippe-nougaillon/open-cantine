class DataFile < ApplicationRecord
  
  def self.save(upload, mairie_id)
    name =  upload['datafile'].original_filename
    directory = ["public/data/",mairie_id.to_s]
    # create the file path
    path = File.join(directory, name)
    # write the file
    File.open(path, "wb") { |f| f.write(upload['datafile'].read) }
  end

end
