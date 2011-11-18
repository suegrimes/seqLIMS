module SeqLibsHelper
  def exclude_adapters(adapters, plex_char)
    adapters.reject! {|adapter| adapter.c_value[0,1] == plex_char}
    return adapters
  end
end