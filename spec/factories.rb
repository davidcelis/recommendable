Factory.define :user do |f|
  f.username "test_user_%d"
end

Factory.define :movie do |f|
  f.title "test_movie_%d"
  f.year 2001
end

Factory.define :bully do |f|
  f.username "bad_user_%d"
end

Factory.define :php_framework do |f|
  f.name "CakePHP"
end
