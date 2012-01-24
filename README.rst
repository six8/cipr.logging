============
Cipr Logging
============

A logging package similar to Python's logging module.

Installation
============

Installation is done with `cipr <http://github.com/six8/corona-cipr>`_

::

	cipr install git://github.com/six8/cipr.logging.git

Usage
=====

::

	local cipr = require 'cipr'
	local log = cipr.import('cipr.logging').getLogger(...)
	log:setLevel(log.DEBUG)

	local x = 1

	log:info('Started')
	log:debug('x = %s', x)


