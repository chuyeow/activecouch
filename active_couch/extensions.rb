module ActiveCouch
  String.class_eval do
    def methodize
      s = self.dup
      s.gsub(/\@/, '')
    end
  end
end