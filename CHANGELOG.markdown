Changelog
=========

0.1.2 (current version)
-----------------------

* Fix an issue that could cause similarity values between users to be incorrect.
* `User#common_likes_with` and `User#common_dislikes_with` now return the actual Model instances by default. Accordingly, these methods are no longer private.

0.1.1
-----
* Introduce the "stashed item" feature. This gives the ability for users to save an item in a list to try later, while at the same time removing it from their list of recommendations. This lets your users keep getting new recommendations without necessarily having to rate what they know they want to try.

0.1.0
-----
* Welcome to recommendable!
