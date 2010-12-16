############################################################
# Copyright (c) 2010, iGenesis Ltda.                       #
# Author: Gustavo Machado C. Gama <gustavo.gama@gmail.com> #
############################################################

require 'hashie'

module Google; module Reader;

class UnderscoreMash < Hashie::Mash
    
    def initialize(hash = nil, default = nil, &blk)
        super(hash, default, &blk)
    end

    protected

    def convert_key(key)
        underscore(key.to_s)
    end

    private
    
    # stolen/adapted from ActiveSuport::Inflector
    def underscore(camel_cased_word)
        camel_cased_word.to_s.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
                              gsub(/([a-z\d])([A-Z])/,'\1_\2').
                              tr("-", "_").
                              downcase
    end
end

end; end # module Google::Reader
