module SeqLibsHelper
  def exclude_adapters(adapters, plex_char)
    adapters.reject! {|adapter| adapter.c_value[0,1] == plex_char}
    return adapters
  end
  
  def sample_conc_string(sample_conc, uom)
    conc = (sample_conc ? number_with_precision(sample_conc, :precision => 2) : '--')
    return [conc, uom].join(' ')
  end
end