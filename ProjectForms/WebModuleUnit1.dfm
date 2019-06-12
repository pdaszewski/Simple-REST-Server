object ModulWEB: TModulWEB
  OldCreateOrder = False
  Actions = <
    item
      Default = True
      Name = 'ack_default'
      PathInfo = '/'
      OnAction = WebModule1DefaultHandlerAction
    end
    item
      MethodType = mtGet
      Name = 'ack_show_categories'
      PathInfo = '/show_categories'
      OnAction = ModulWEBack_show_categoriesAction
    end>
  Height = 206
  Width = 511
end
