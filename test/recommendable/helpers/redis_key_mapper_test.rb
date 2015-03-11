$LOAD_PATH.unshift File.expand_path('../../test', __FILE__)
require 'test_helper'

class RedisKeyMapperTest < Minitest::Test
  def test_output_of_liked_set_for
    assert_equal 'recommendable:users:1:liked_movies', Recommendable::Helpers::RedisKeyMapper.liked_set_for(Movie, 1)
  end

  def test_output_of_disliked_set_for
    assert_equal 'recommendable:users:1:disliked_movies', Recommendable::Helpers::RedisKeyMapper.disliked_set_for(Movie, 1)
  end

  def test_output_of_hidden_set_for
    assert_equal 'recommendable:users:1:hidden_movies', Recommendable::Helpers::RedisKeyMapper.hidden_set_for(Movie, 1)
  end

  def test_output_of_bookmarked_set_for
    assert_equal 'recommendable:users:1:bookmarked_movies', Recommendable::Helpers::RedisKeyMapper.bookmarked_set_for(Movie, 1)
  end

  def test_output_of_recommended_set_for
    assert_equal 'recommendable:users:1:recommended_movies', Recommendable::Helpers::RedisKeyMapper.recommended_set_for(Movie, 1)
  end

  def test_output_of_similarity_set_for
    assert_equal 'recommendable:users:1:similarities', Recommendable::Helpers::RedisKeyMapper.similarity_set_for(1)
  end

  def test_output_of_liked_by_set_for
    assert_equal 'recommendable:movies:1:liked_by', Recommendable::Helpers::RedisKeyMapper.liked_by_set_for(Movie, 1)
  end

  def test_output_of_disliked_by_set_for
    assert_equal 'recommendable:movies:1:disliked_by', Recommendable::Helpers::RedisKeyMapper.disliked_by_set_for(Movie, 1)
  end

  def test_output_of_score_set_for
    assert_equal 'recommendable:movies:scores', Recommendable::Helpers::RedisKeyMapper.score_set_for(Movie)
  end

  def test_output_of_liked_set_for_subclass_of_ratable
    assert_equal 'recommendable:users:1:liked_movies', Recommendable::Helpers::RedisKeyMapper.liked_set_for(Documentary, 1)
  end

  def test_output_of_disliked_set_for_subclass_of_ratable
    assert_equal 'recommendable:users:1:disliked_movies', Recommendable::Helpers::RedisKeyMapper.disliked_set_for(Documentary, 1)
  end

  def test_output_of_hidden_set_for_subclass_of_ratable
    assert_equal 'recommendable:users:1:hidden_movies', Recommendable::Helpers::RedisKeyMapper.hidden_set_for(Documentary, 1)
  end

  def test_output_of_bookmarked_set_for_subclass_of_ratable
    assert_equal 'recommendable:users:1:bookmarked_movies', Recommendable::Helpers::RedisKeyMapper.bookmarked_set_for(Documentary, 1)
  end

  def test_output_of_recommended_set_for_subclass_of_ratable
    assert_equal 'recommendable:users:1:recommended_movies', Recommendable::Helpers::RedisKeyMapper.recommended_set_for(Documentary, 1)
  end

  def test_output_of_liked_by_set_for_subclass_of_ratable
    assert_equal 'recommendable:movies:1:liked_by', Recommendable::Helpers::RedisKeyMapper.liked_by_set_for(Documentary, 1)
  end

  def test_output_of_disliked_by_set_for_subclass_of_ratable
    assert_equal 'recommendable:movies:1:disliked_by', Recommendable::Helpers::RedisKeyMapper.disliked_by_set_for(Documentary, 1)
  end

  def test_output_of_score_set_for_subclass_of_ratable
    assert_equal 'recommendable:movies:scores', Recommendable::Helpers::RedisKeyMapper.score_set_for(Documentary)
  end

  def test_output_of_liked_set_for_ratable_subclass_of_nonratable
    assert_equal 'recommendable:users:1:liked_cars', Recommendable::Helpers::RedisKeyMapper.liked_set_for(Car, 1)
  end

  def test_output_of_disliked_set_for_ratable_subclass_of_nonratable
    assert_equal 'recommendable:users:1:disliked_cars', Recommendable::Helpers::RedisKeyMapper.disliked_set_for(Car, 1)
  end

  def test_output_of_hidden_set_for_ratable_subclass_of_nonratable
    assert_equal 'recommendable:users:1:hidden_cars', Recommendable::Helpers::RedisKeyMapper.hidden_set_for(Car, 1)
  end

  def test_output_of_bookmarked_set_for_ratable_subclass_of_nonratable
    assert_equal 'recommendable:users:1:bookmarked_cars', Recommendable::Helpers::RedisKeyMapper.bookmarked_set_for(Car, 1)
  end

  def test_output_of_recommended_set_for_ratable_subclass_of_nonratable
    assert_equal 'recommendable:users:1:recommended_cars', Recommendable::Helpers::RedisKeyMapper.recommended_set_for(Car, 1)
  end

  def test_output_of_liked_by_set_for_ratable_subclass_of_nonratable
    assert_equal 'recommendable:cars:1:liked_by', Recommendable::Helpers::RedisKeyMapper.liked_by_set_for(Car, 1)
  end

  def test_output_of_disliked_by_set_for_ratable_subclass_of_nonratable
    assert_equal 'recommendable:cars:1:disliked_by', Recommendable::Helpers::RedisKeyMapper.disliked_by_set_for(Car, 1)
  end

  def test_output_of_score_set_for_ratable_subclass_of_nonratable
    assert_equal 'recommendable:cars:scores', Recommendable::Helpers::RedisKeyMapper.score_set_for(Car)
  end

end
