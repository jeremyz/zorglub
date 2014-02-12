# zorglub
    by Jérémy Zurcher
    http://asynk.ch
[![Build Status](https://secure.travis-ci.org/jeremyz/zorglub.png)](http://travis-ci.org/jeremyz/zorglub)
[![Coverage Status](https://coveralls.io/repos/jeremyz/zorglub/badge.png?branch=master)](https://coveralls.io/r/jeremyz/zorglub?branch=master)
[![Gem Version](https://badge.fury.io/rb/zorglub.png)](http://badge.fury.io/rb/zorglub)

## DESCRIPTION:

a nano web application framework based on [rack](http://rack.rubyforge.org/)

## FEATURES:

* class#method mapping scheme (/class_mapping/method_name/*args)
* class level layout and engine specification
* method level layout, engine and view specification
* before_all and after_all methods callbacks
* redirection
* partial
* class level inherited variables
* session

## SYNOPSIS:

For a simple test application run:
* rackup ./example/sample.ru

Don't forget to look at
* the spec/ folder

## REQUIREMENTS:

* rack

## DOWNLOAD/INSTALL:

From rubygems:

  [sudo] gem install zorglub

or from the git repository on github:

git clone git://github.com/jeremyz/zorglub.git && cd zorglub && rake install

## RESOURCES:

You can find this project in a few places:

Online repositories:

* https://github.com/jeremyz/zorglub
* http://cgit.asynk.ch/cgi-bin/cgit/zorglub/

## LICENSE:

[MIT](http://www.opensource.org/licenses/MIT) see [MIT_LICENSE](https://github.com/jeremyz/zorglub/blob/master/MIT-LICENSE)

