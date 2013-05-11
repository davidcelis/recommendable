Factory.define(:user) do |f|
  f.email "user%d@example.com"
end

Factory.define(:movie) do |f|
  f.title "%{year}: A Space Odyssey"
  f.year  { "200%d".to_i }
end

Factory.define(:book) do |f|
  f.title  "Harry Potter Vol. %d"
  f.author "J.K. Rowling"
end

Factory.define(:rock) do |f|
  f.name "Boring Specimen No. %d"
end
