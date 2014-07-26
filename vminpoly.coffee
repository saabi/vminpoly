XMLHttpFactories = [
  -> new XMLHttpRequest(),
  -> new ActiveXObject("Msxml2.XMLHTTP"),
  -> new ActiveXObject("Msxml3.XMLHTTP"),
  -> new ActiveXObject("Microsoft.XMLHTTP")]

createXMLHTTPObject = ->
  xmlhttp = false
  i = 0

  while i < XMLHttpFactories.length
    try
      xmlhttp = XMLHttpFactories[i++]()
    catch e
      continue
    break
  xmlhttp

##toCamelCase = (s) ->
##  s.replace(/-([a-z])/g, (g) ->
##    return g[1].toUpperCase()

ajax = (url, onload) ->
  xmlhttp = createXMLHTTPObject()
  xmlhttp.onreadystatechange = ->
    unless xmlhttp.readyState is 4
      return
    unless xmlhttp.status is 200 || url.match(/^file:\/\/\//)
      throw "Error!"
    onload xmlhttp.responseText
    return
  xmlhttp.open "GET", url, true
  xmlhttp.send()
  return

# get window dimensions, cross-browser compatible
# Thanks to: Stefano Gargiulo
getViewportSize = ->
  x = 0
  y = 0
  if window.innerHeight # all except Explorer < 9
    x = window.innerWidth
    y = window.innerHeight
  else if document.documentElement and document.documentElement.clientHeight
    # Explorer 6 Strict Mode
    x = document.documentElement.clientWidth
    y = document.documentElement.clientHeight
  else if document.body # other Explorers < 9
    x = document.body.clientWidth
    y = document.body.clientHeight
  width: x
  height: y

initLayoutEngine = () ->
  analyzeStyleRule = (rule) ->
    declarations = []
    for declaration in rule.value
      hasDimension = false
      for token in declaration.value
        if token.tokenType is 'DIMENSION' and (token.unit is 'vmin' or token.unit is 'vh' or token.unit is 'vw')
          hasDimension = true
      if hasDimension
        declarations.push declaration
    rule.value = declarations
    declarations
  analyzeStylesheet = (sheet) ->
    rules = []
    for rule in sheet.value
      switch rule.type
        when 'STYLE-RULE'
          decs = analyzeStyleRule rule
          unless decs.length is 0
            rules.push rule
        when 'AT-RULE'
          atRules = analyzeStylesheet rule
          unless atRules.length is 0
            rules.push rule
    sheet.value = rules
    rules

  onresize = ->
    vpDims = getViewportSize()

    dims = 
      vh: vpDims.height / 100
      vw: vpDims.width / 100
    dims.vmin = Math.min dims.vh, dims.vw

    vpAspectRatio = vpDims.width / vpDims.height

    map = (a, f) ->
      if a.map?
        a.map f
      else
        a1 = []
        for e in a
          a1.push f e
        a1

    generateRuleCode = (rule) ->
      declarations = []

      ruleCss = (map rule.selector, (o) -> if o.toSourceString? then o.toSourceString() else '').join ''
      ruleCss += "{"
      for declaration in rule.value
        ruleCss += declaration.name
        ruleCss += ":"
        for token in declaration.value
          if token.tokenType is 'DIMENSION' and (token.unit is 'vmin' or token.unit is 'vh' or token.unit is 'vw')
            ruleCss += "#{Math.floor(token.num*dims[token.unit])}px"
          else
            ruleCss += token.toSourceString()
        ruleCss += ";"
      ruleCss += "}\r"
      ruleCss
    generateSheetCode = (sheet) ->
      sheetCss = ''
      for rule in sheet.value
        switch rule.type
          when 'STYLE-RULE'
            sheetCss += generateRuleCode rule
          when 'AT-RULE'
            if rule.name is 'media'
              prelude = ''
              mar = false
              nums = []
              for t in rule.prelude
                if t.name is '('
                  prelude += '('
                  for t1 in t.value
                    source = if t1.toSourceString? then t1.toSourceString() else ''
                    if t1.tokenType is 'IDENT' and source is 'max-aspect-ratio'
                      mar = true
                    if t1.tokenType is 'NUMBER' 
                      nums.push parseInt source

                    prelude += source
                  #prelude += (map t.value, (o) -> if o.toSourceString? then o.toSourceString() else '').join ''
                  #prelude += t.value.join ''
                  prelude += ')'
                else
                  prelude += t.toSourceString()
              if vpAspectRatio < nums[0] / nums[1]
                sheetCss += generateSheetCode rule
            else
              prelude = ''
              for t in rule.prelude
                if t.name is '('
                  prelude += '('
                  prelude += (map t.value, (o) -> if o.toSourceString? then o.toSourceString() else '').join ''
                  #prelude += t.value.join ''
                  prelude += ')'
                else
                  prelude += t.toSourceString()
              sheetCss += "@#{rule.name} #{prelude} {"
              sheetCss += generateSheetCode rule
              sheetCss += '}\n'
      sheetCss
    css = ''
    for url, sheet of sheets
      css += generateSheetCode sheet
    if styleElement.styleSheet?
      styleElement.styleSheet.cssText = css
    else
      styleElement.innerHTML = css

  sheets = {}
  styleElement = document.createElement 'style'
  head = document.getElementsByTagName('head')[0]
  head.appendChild styleElement

  links = document.getElementsByTagName 'link'
  innerSheetCount = 0;
  outerSheetCount = 0;
  for i in links
    unless i.rel is 'stylesheet'
      continue
    innerSheetCount++;
    ajax i.href, (cssText) ->
      tokenlist = tokenize cssText
      sheet = parse tokenlist
      analyzeStylesheet sheet
      sheets[i.href] = sheet
      outerSheetCount++
      if outerSheetCount is innerSheetCount
        window.onresize()
      return

  window.onresize = onresize
  return

initLayoutEngine()


