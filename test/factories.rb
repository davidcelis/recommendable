Factory.define(:user) do |f|
  f.email 'user%d@example.com'
end

Factory.define(:movie) do |f|
  f.title '%{year}: A Space Odyssey'
  f.year  { '200%d'.to_i }
end

Factory.define(:documentary) do |f|
  f.title '%{year}: A Space Documentary'
  f.year  { '200%d'.to_i }
  f.type 'Documentary'
end

Factory.define(:book) do |f|
  f.title  'Harry Potter Vol. %d'
  f.author 'J.K. Rowling'
end

Factory.define(:rock) do |f|
  f.name 'Boring Specimen No. %d'
end

Factory.define(:vehicle) do |f|
  f.color 'blue'
end

Factory.define(:car) do |f|
  f.type 'Car'
  f.color 'red'
end

Factory.define(:boat) do |f|
  f.type 'Boat'
  f.color 'white'
end
