############################################################
# Copyright (c) 2010, iGenesis Ltda.                       #
# Author: Gustavo Machado C. Gama <gustavo.gama@gmail.com> #
############################################################

require 'google-reader/underscore-mash'
require 'google-reader/item'

module Google; module Reader;

class ItemRef < UnderscoreMash
    def item_id
        Item.str_id(self.id)
    end
end

end; end # module Google::Reader
