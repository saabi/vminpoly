sheets = {}
styleElement = document.createElement 'style'
head = document.getElementsByTagName('head')[0]
head.appendChild styleElement

##toCamelCase = (s) ->
##  s.replace(/-([a-z])/g, (g) ->
##    return g[1].toUpperCase()
ajax = (url, onload) ->
  if window.XMLHttpRequest
    xmlhttp = new XMLHttpRequest()
  else # code for IE6, IE5
    xmlhttp = new ActiveXObject("Microsoft.XMLHTTP")
  xmlhttp.onload = ->
    onload this.responseText
    return
  xmlhttp.open "GET", url, true
  xmlhttp.send()
  return

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

  links = document.getElementsByTagName 'link'
  for i in links
    unless i.rel is 'stylesheet'
      continue
    ajax i.href, (cssText) ->
      tokenlist = tokenize cssText
      sheet = parse tokenlist
      analyzeStylesheet sheet
      sheets[i.href] = sheet
      return

initLayoutEngine()

onresize = ->
  dims = 
    vh: document.documentElement.offsetHeight / 100
    vw: document.documentElement.offsetWidth / 100
  dims.vmin = Math.min dims.vh, dims.vw

  generateRuleCode = (rule) ->
    declarations = []
    ruleCss = rule.selector.join ''
    ruleCss += "{"
    for declaration in rule.value
      ruleCss += declaration.name
      ruleCss += ":"
      for token in declaration.value
        if token.tokenType is 'DIMENSION' and (token.unit is 'vmin' or token.unit is 'vh' or token.unit is 'vw')
          ruleCss += "#{Math.floor(token.num*dims[token.unit])}px"
        else
          ruleCss += token.toString()
      ruleCss += ";"
    ruleCss += "}"
    ruleCss
  generateSheetCode = (sheet) ->
    sheetCss = ''
    for rule in sheet.value
      switch rule.type
        when 'STYLE-RULE'
          sheetCss += generateRuleCode rule
        when 'AT-RULE'
          prelude = ''
          for t in rule.prelude
            if t.name is '('
              prelude += '('
              prelude += t.value.join ''
              prelude += ')'
            else
              prelude += t.toString()
          sheetCss += "@#{rule.name} #{prelude} {"
          sheetCss += generateSheetCode rule
          sheetCss += '}'
    sheetCss
  css = ''
  for url, sheet of sheets
    css += generateSheetCode sheet
  styleElement.innerHTML = css

window.onresize = onresize
setTimeout onresize, 100

