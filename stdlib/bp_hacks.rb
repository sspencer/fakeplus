class Array
  def / len
    a = []
    each_with_index do |x, i|
      a << [] if i % len == 0
      a.last << x
    end
    a
  end
end

class Class
  def bp_version v
    @bp_version = v.split('.').map { |x| x.to_i }
  end

  def bp_doc m, desc = nil
    @bp_doc ||= {}
    m, desc = nil, m unless desc
    @bp_doc[m] = parse_bp_doc(m, desc)
  end

  def parse_bp_doc mname, desc
    mname ||= :initialize
    ar = instance_method(mname).arity rescue -1
    ar = ar.abs - 1 if ar < 0

    doc, *m = desc.split(/^\s+\((\w+:\s*\w+)\)\s+/)
    i = -1
    m = (m/2).map do |arg, adoc|
      i += 1
      aname, atype = arg.split(/:\s*/, 2)
      {'name' => aname, 'type' => atype, 'documentation' => adoc,
       'required' => ar > i}
    end.compact
    [doc.strip, m]
  end

  def bp_wrap meth, margs
    alias_method "bp_#{meth}", meth
    case meth when 'initialize'
      define_method meth do |bp_args|
        args = []
        send("bp_#{meth}", *args)
      end
    else
      define_method meth do |bp, bp_args|
        begin
          args = []
          if margs
            args = margs.map { |a| bp_args[a['name']] }
          end
          bp.complete(send("bp_#{meth}", *args))
        rescue Exception => e
          bp.error('FAIL', "Error: #{e}")
        end
      end
    end
  end

  def to_corelet
    unless @is_corelet
      bp_wrap 'initialize', []
      @bp_doc.each do |k, (v, m)|
        next unless k
        bp_wrap k, m
      end
      @is_corelet = true
    end

    doc, init = @bp_doc[nil]
    hsh = 
      {'class' => self.name,
       'name' => self.name,
       'major_version' => @bp_version[0],
       'minor_version' => @bp_version[1],
       'micro_version' => @bp_version[2],
       'documentation' => doc,
       'functions' => []}
    @bp_doc.each do |k, (v, m)|
      next unless k
      hsh['functions'] << {
        'name' => k.to_s,
        'documentation' => v,
        'arguments' => m
      }
    end
    hsh
  end
end
