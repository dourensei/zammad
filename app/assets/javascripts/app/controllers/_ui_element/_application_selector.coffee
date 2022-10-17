# coffeelint: disable=camel_case_classes
class App.UiElement.ApplicationSelector
  @defaults: (attribute = {}, params = {}) ->
    defaults = ['ticket.state_id']

    groups =
      ticket:
        name: __('Ticket')
        model: 'Ticket'
      article:
        name: __('Article')
        model: 'TicketArticle'
      customer:
        name: __('Customer')
        model: 'User'
      organization:
        name: __('Organization')
        model: 'Organization'

    if attribute.executionTime
      groups.execution_time =
        name: __('Execution Time')

    operators_type =
      '^datetime$': [__('today'), __('before (absolute)'), __('after (absolute)'), __('before (relative)'), __('after (relative)'), __('within next (relative)'), __('within last (relative)'), __('till (relative)'), __('from (relative)')]
      '^timestamp$': [__('today'), __('before (absolute)'), __('after (absolute)'), __('before (relative)'), __('after (relative)'), __('within next (relative)'), __('within last (relative)'), __('till (relative)'), __('from (relative)')]
      '^date$': [__('today'), 'before (absolute)', 'after (absolute)', 'before (relative)', 'after (relative)', 'within next (relative)', 'within last (relative)']
      'boolean$': [__('is'), __('is not')]
      'integer$': [__('is'), __('is not')]
      '^radio$': [__('is'), __('is not')]
      '^select$': [__('is'), __('is not')]
      '^multiselect$': [__('contains all'), __('contains one'), __('contains all not'), __('contains one not')]
      '^tree_select$': [__('is'), __('is not')]
      '^multi_tree_select$': [__('contains all'), __('contains one'), __('contains all not'), __('contains one not')]
      '^input$': [__('contains'), __('contains not')]
      '^richtext$': [__('contains'), __('contains not')]
      '^textarea$': [__('contains'), __('contains not')]
      '^tag$': [__('contains all'), __('contains one'), __('contains all not'), __('contains one not')]

    if attribute.hasChanged
      operators_type =
        '^datetime$': [__('before (absolute)'), __('after (absolute)'), __('before (relative)'), __('after (relative)'), __('within next (relative)'), __('within last (relative)'), __('till (relative)'), __('from (relative)'), __('has changed')]
        '^timestamp$': [__('before (absolute)'), __('after (absolute)'), __('before (relative)'), __('after (relative)'), __('within next (relative)'), __('within last (relative)'), __('till (relative)'), __('from (relative)'), __('has changed')]
        '^date$': [__('before (absolute)'), __('after (absolute)'), __('before (relative)'), __('after (relative)'), __('within next (relative)'), __('within last (relative)'), __('till (relative)'), __('from (relative)'), __('has changed')]
        'boolean$': [__('is'), __('is not'), __('has changed')]
        'integer$': [__('is'), __('is not'), __('has changed')]
        '^radio$': [__('is'), __('is not'), __('has changed')]
        '^select$': [__('is'), __('is not'), __('has changed')]
        '^multiselect$': [__('contains all'), __('contains one'), __('contains all not'), __('contains one not')]
        '^tree_select$': [__('is'), __('is not'), __('has changed')]
        '^multi_tree_select$': [__('contains all'), __('contains one'), __('contains all not'), __('contains one not')]
        '^input$': [__('contains'), __('contains not'), __('has changed')]
        '^richtext$': [__('contains'), __('contains not'), __('has changed')]
        '^textarea$': [__('contains'), __('contains not'), __('has changed')]
        '^tag$': [__('contains all'), __('contains one'), __('contains all not'), __('contains one not')]

    operators_name =
      '_id$': [__('is'), __('is not')]
      '_ids$': [__('is'), __('is not')]

    if attribute.hasChanged
      operators_name =
        '_id$': [__('is'), __('is not'), __('has changed')]
        '_ids$': [__('is'), __('is not'), __('has changed')]

    # merge config
    elements = {}

    if attribute.article is false
      delete groups.article

    if attribute.action
      elements['ticket.action'] =
        name: 'action'
        display: __('Action')
        tag: 'select'
        null: false
        translate: true
        options:
          create:                  'created'
          update:                  'updated'
          'update.merged_into':    'merged into'
          'update.received_merge': 'received merge'
        operator: [__('is'), __('is not')]

    for groupKey, groupMeta of groups
      if groupKey is 'execution_time'
        if attribute.executionTime
          elements['execution_time.calendar_id'] =
            name: 'calendar_id'
            display: __('Calendar')
            tag: 'select'
            relation: 'Calendar'
            null: false
            translate: false
            operator: [__('is in working time'), __('is not in working time')]

      else
        attributesByObject = App.ObjectManagerAttribute.selectorAttributesByObject()
        configureAttributes = attributesByObject[groupMeta.model] || []
        for config in configureAttributes
          # ignore passwords and relations
          if config.type isnt 'password' && config.name.substr(config.name.length-4,4) isnt '_ids' && config.searchable isnt false
            config.default  = undefined
            if config.tag is 'textarea'
              config.expanding = false
            if config.type is 'email' || config.type is 'tel'
              config.type = 'text'
            if config.tag is 'select'
              config.multiple = true
            for operatorRegEx, operator of operators_type
              myRegExp = new RegExp(operatorRegEx, 'i')
              if config.tag && config.tag.match(myRegExp)
                config.operator = operator
              elements["#{groupKey}.#{config.name}"] = config
            for operatorRegEx, operator of operators_name
              myRegExp = new RegExp(operatorRegEx, 'i')
              if config.name && config.name.match(myRegExp)
                config.operator = operator
              elements["#{groupKey}.#{config.name}"] = config

    if attribute.out_of_office
      elements['ticket.out_of_office_replacement_id'] =
        name: 'out_of_office_replacement_id'
        display: __('Out of office replacement')
        tag: 'autocompletion_ajax'
        relation: 'User'
        null: false
        translate: true
        operator: [__('is'), __('is not')]

    # Remove 'has changed' operator from attributes which don't support the operator.
    ['ticket.created_at', 'ticket.updated_at'].forEach (element_name) ->
      elements[element_name]['operator'] = elements[element_name]['operator'].filter (item) -> item != 'has changed'

    elements['ticket.mention_user_ids'] =
      name: 'mention_user_ids'
      display: __('Subscribe')
      tag: 'autocompletion_ajax'
      relation: 'User'
      null: false
      translate: true
      operator: [__('is'), __('is not')]

    [defaults, groups, elements]

  @rowContainer: (groups, elements, attribute) ->
    row = $( App.view('generic/application_selector_row')(
      attribute: attribute
      pre_condition: @HasPreCondition()
    ) )
    selector = @buildAttributeSelector(groups, elements)
    row.find('.js-attributeSelector').prepend(selector)
    row

  @emptyBody: (attribute) ->
    return $( App.view('generic/application_selector_empty')(
      attribute: attribute
    ) )

  @render: (attribute, params = {}) ->

    [defaults, groups, elements] = @defaults(attribute, params)

    item = $( App.view('generic/application_selector')(attribute: attribute) )

    # add filter
    item.on('click', '.js-add', (e) =>
      element = $(e.target).closest('.js-filterElement')

      # add first available attribute
      field = undefined
      for groupAndAttribute, _config of elements
        if @hasDuplicateSelector()
          field = groupAndAttribute
          break
        else if !item.find(".js-attributeSelector [value=\"#{groupAndAttribute}\"]:selected").get(0)
          field = groupAndAttribute
          break
      return if !field
      row = @rowContainer(groups, elements, attribute)

      emptyRow = item.find('div.horizontal-filter-body')
      if emptyRow.find('input.empty:hidden').length > 0 && @hasEmptySelectorAtStart()
        emptyRow.parent().replaceWith(row)
      else
        element.after(row)
        row.find('.js-attributeSelector select').trigger('change')

      @rebuildAttributeSelectors(item, row, field, elements, {}, attribute)

      if attribute.preview isnt false
        @preview(item)
    )

    # remove filter
    item.on('click', '.js-remove', (e) =>
      return if $(e.currentTarget).hasClass('is-disabled')

      if @hasEmptySelectorAtStart()
        if item.find('.js-remove').length > 1
          $(e.target).closest('.js-filterElement').remove()
        else
          $(e.target).closest('.js-filterElement').find('div.horizontal-filter-body').html(@emptyBody(attribute))
      else
        $(e.target).closest('.js-filterElement').remove()

      @updateAttributeSelectors(item)
      if attribute.preview isnt false
        @preview(item)
    )

    paramValue = {}
    for groupAndAttribute, meta of params[attribute.name]
      continue if !elements[groupAndAttribute]
      paramValue[groupAndAttribute] = meta

    # build initial params
    if !_.isEmpty(paramValue)
      @renderParamValue(item, attribute, params, paramValue)
    else
      if @hasEmptySelectorAtStart()
        row = @rowContainer(groups, elements, attribute)
        row.find('.horizontal-filter-body').html(@emptyBody(attribute))
        item.filter('.js-filter').append(row)
      else
        for groupAndAttribute in defaults

          # build and append
          row = @rowContainer(groups, elements, attribute)
          @rebuildAttributeSelectors(item, row, groupAndAttribute, elements, {}, attribute)
          item.filter('.js-filter').append(row)

    # change attribute selector
    item.on('change', '.js-attributeSelector select', (e) =>
      elementRow = $(e.target).closest('.js-filterElement')
      groupAndAttribute = elementRow.find('.js-attributeSelector option:selected').attr('value')
      return if !groupAndAttribute
      @rebuildAttributeSelectors(item, elementRow, groupAndAttribute, elements, {}, attribute)
      @updateAttributeSelectors(item)
    )

    # change operator selector
    item.on('change', '.js-operator select', (e) =>
      elementRow = $(e.target).closest('.js-filterElement')
      groupAndAttribute = elementRow.find('.js-attributeSelector option:selected').attr('value')
      return if !groupAndAttribute
      @buildOperator(item, elementRow, groupAndAttribute, elements, {}, attribute)
    )

    # bind for preview
    if attribute.preview isnt false
      search = =>
        @preview(item)

      triggerSearch = ->
        item.find('.js-previewCounterContainer').addClass('hide')
        item.find('.js-previewLoader').removeClass('hide')
        App.Delay.set(
          search,
          600,
          'preview',
        )

      item.on('change', 'select', (e) ->
        triggerSearch()
      )
      item.on('change keyup', 'input', (e) ->
        triggerSearch()
      )

    @disableRemoveForOneAttribute(item)
    item

  @renderParamValue: (item, attribute, params, paramValue) ->
    [defaults, groups, elements] = @defaults(attribute, params)

    for groupAndAttribute, meta of paramValue

      # build and append
      row = @rowContainer(groups, elements, attribute)
      @rebuildAttributeSelectors(item, row, groupAndAttribute, elements, meta, attribute)
      item.filter('.js-filter').append(row)

  @preview: (item) ->
    params = App.ControllerForm.params(item)
    App.Ajax.request(
      id:    'application_selector'
      type:  'POST'
      url:   "#{App.Config.get('api_path')}/tickets/selector"
      data:        JSON.stringify(params)
      processData: true,
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        item.find('.js-previewCounterContainer').removeClass('hide')
        item.find('.js-previewLoader').addClass('hide')
        @ticketTable(data.ticket_ids, data.ticket_count, item)
    )

  @ticketTable: (ticket_ids, ticket_count, item) ->
    item.find('.js-previewCounter').html(ticket_count)
    new App.TicketList(
      tableId:    'ticket-selector'
      el:         item.find('.js-previewTable')
      ticket_ids: ticket_ids
    )

  @buildAttributeSelector: (groups, elements) ->
    selection = $('<select class="form-control"></select>')
    for groupKey, groupMeta of groups
      groupKeyClass = groupKey.replace('.', '-')
      displayName = App.i18n.translateInline(groupMeta.name)
      selection.closest('select').append("<optgroup label=\"#{displayName}\" class=\"js-#{groupKeyClass}\"></optgroup>")
      optgroup = selection.find("optgroup.js-#{groupKeyClass}")
      for elementKey, elementGroup of elements
        spacer = elementKey.split(/\./).slice(0, -1).join('.')
        if spacer is groupKey
          attributeConfig = elements[elementKey]
          if attributeConfig.operator
            displayName = App.i18n.translateInline(attributeConfig.display)
            optgroup.append("<option value=\"#{elementKey}\">#{displayName}</option>")
    selection

  # disable - if we only have one attribute
  @disableRemoveForOneAttribute: (elementFull) ->
    if @hasEmptySelectorAtStart()
      if elementFull.find('div.horizontal-filter-body input.empty:hidden').length > 0 && elementFull.find('.js-remove').length < 2
        elementFull.find('.js-remove').addClass('is-disabled')
      else
        elementFull.find('.js-remove').removeClass('is-disabled')
    else
      if elementFull.find('.js-attributeSelector select').length > 1
        elementFull.find('.js-remove').removeClass('is-disabled')
      else
        elementFull.find('.js-remove').addClass('is-disabled')

  @updateAttributeSelectors: (elementFull) ->
    if !@hasDuplicateSelector()

      # enable all
      elementFull.find('.js-attributeSelector select option').prop('disabled', false)

      # disable all used attributes
      elementFull.find('.js-attributeSelector select').each(->
        keyLocal = $(@).val()
        elementFull.find('.js-attributeSelector select option[value="' + keyLocal + '"]').attr('disabled', true)
      )

    # disable - if we only have one attribute
    @disableRemoveForOneAttribute(elementFull)

  @rebuildAttributeSelectors: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->

    # set attribute
    if groupAndAttribute
      elementRow.find('.js-attributeSelector select').val(groupAndAttribute)

    @buildOperator(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)

  @mapOperatorDisplayName: (operator) ->
    return operator

  @buildOperator: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->
    currentOperator = elementRow.find('.js-operator option:selected').attr('value')

    name = "#{attribute.name}::#{groupAndAttribute}::operator"

    if !meta.operator && currentOperator
      meta.operator = currentOperator

    selection = $("<select class=\"form-control\" name=\"#{name}\"></select>")

    attributeConfig = elements[groupAndAttribute]
    if attributeConfig.operator

      # check if operator exists
      operatorExists = false
      for operator in attributeConfig.operator
        if meta.operator is operator
          operatorExists = true
          break

      if !operatorExists
        for operator in attributeConfig.operator
          meta.operator = operator
          break

      for operator in attributeConfig.operator
        operatorName = App.i18n.translateInline(@mapOperatorDisplayName(operator))
        selected = ''
        if !groupAndAttribute.match(/^ticket/) && operator is 'has changed'
          # do nothing, only show "has changed" in ticket attributes
        else
          if meta.operator is operator
            selected = 'selected="selected"'
          selection.append("<option value=\"#{operator}\" #{selected}>#{operatorName}</option>")
      selection

    elementRow.find('.js-operator select').replaceWith(selection)

    if @HasPreCondition()
      @buildPreCondition(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)
    else
      @buildValue(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)

  @buildPreCondition: (elementFull, elementRow, groupAndAttribute, elements, meta, attributeConfig) ->
    currentOperator = elementRow.find('.js-operator option:selected').attr('value')
    currentPreCondition = elementRow.find('.js-preCondition option:selected').attr('value')

    if !meta.pre_condition
      meta.pre_condition = currentPreCondition

    toggleValue = =>
      preCondition = elementRow.find('.js-preCondition option:selected').attr('value')
      if preCondition isnt 'specific'
        elementRow.find('.js-value select').html('')
        elementRow.find('.js-value').addClass('hide')
      else
        elementRow.find('.js-value').removeClass('hide')
        @buildValue(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)

    # force to use auto completion on user lookup
    attribute = _.clone(attributeConfig)

    name = "#{attribute.name}::#{groupAndAttribute}::value"
    attributeSelected = elements[groupAndAttribute]

    preCondition = false
    if attributeSelected.relation is 'User'
      preCondition = 'user'
      attribute.tag = 'user_autocompletion'
    if attributeSelected.relation is 'Organization'
      preCondition = 'org'
      attribute.tag = 'autocompletion_ajax'
    if !preCondition
      elementRow.find('.js-preCondition select').html('')
      elementRow.find('.js-preCondition').closest('.controls').addClass('hide')
      toggleValue()
      @buildValue(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)
      return

    elementRow.find('.js-preCondition').removeClass('hide')
    name = "#{attribute.name}::#{groupAndAttribute}::pre_condition"

    selection = $("<select class=\"form-control\" name=\"#{name}\" ></select>")
    options = {}
    if preCondition is 'user'
      if attributeConfig.noCurrentUser isnt true
        options['current_user.id'] = App.i18n.translateInline('current user')
      options['specific'] = App.i18n.translateInline('specific user')
      options['not_set'] = App.i18n.translateInline('not set (not defined)')
    else if preCondition is 'org'
      if attributeConfig.noCurrentUser isnt true
        options['current_user.organization_id'] = App.i18n.translateInline('current user organization')
      options['specific'] = App.i18n.translateInline('specific organization')
      options['not_set'] = App.i18n.translateInline('not set (not defined)')

    for key, value of options
      selected = ''
      if key is meta.pre_condition
        selected = 'selected="selected"'
      selection.append("<option value=\"#{key}\" #{selected}>#{App.i18n.translateInline(value)}</option>")
    elementRow.find('.js-preCondition').closest('.controls').removeClass('hide')
    elementRow.find('.js-preCondition select').replaceWith(selection)

    elementRow.find('.js-preCondition select').on('change', (e) ->
      toggleValue()
    )

    @buildValue(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)
    toggleValue()

  @buildValueConfigValue: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->
    return _.clone(attribute.value[groupAndAttribute]['value'])

  @buildValueName: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->
    return "#{attribute.name}::#{groupAndAttribute}::value"

  @buildValue: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->
    name = @buildValueName(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)

    # build new item
    attributeConfig = elements[groupAndAttribute]
    config = _.clone(attributeConfig)

    if config.relation is 'User'
      config.tag = 'user_autocompletion'
    if config.relation is 'Organization'
      config.tag = 'autocompletion_ajax'

    # render ui element
    item = ''
    if config && App.UiElement[config.tag] && meta.operator isnt 'today'
      config['name'] = name
      if attribute.value && attribute.value[groupAndAttribute]
        config['value'] = @buildValueConfigValue(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)
      if 'multiple' of config
        config = @buildValueConfigMultiple(config, meta)
      if config.relation is 'User'
        config.multiple = false
        config.nulloption = false
        config.guess = false
        config.disableCreateObject = true
      if config.relation is 'Organization'
        config.multiple = false
        config.nulloption = false
        config.guess = false
      if config.tag is 'checkbox'
        config.tag = 'select'
      item = @renderConfig(config, meta)
    if meta.operator is 'before (relative)' || meta.operator is 'within next (relative)' || meta.operator is 'within last (relative)' || meta.operator is 'after (relative)' || meta.operator is 'from (relative)' || meta.operator is 'till (relative)'
      config['name'] = "#{attribute.name}::#{groupAndAttribute}"
      if attribute.value && attribute.value[groupAndAttribute]
        config['value'] = _.clone(attribute.value[groupAndAttribute])
      item = App.UiElement['time_range'].render(config, {})

    elementRow.find('.js-value').removeClass('hide').html(item)
    if meta.operator is 'has changed'
      elementRow.find('.js-value').addClass('hide')
      elementRow.find('.js-preCondition').closest('.controls').addClass('hide')
    else
      elementRow.find('.js-value').removeClass('hide')

  @renderConfig: (config, meta) ->
    tagSearch = "#{config.tag}_search"
    return App.UiElement[tagSearch].render(config, {}) if App.UiElement[tagSearch]
    return App.UiElement[config.tag].render(config, {})

  @buildValueConfigMultiple: (config, meta) ->
    config.multiple = true
    config.nulloption = false
    return config

  @humanText: (condition) ->
    none = App.i18n.translateContent('No filter was configured.')
    return [none] if _.isEmpty(condition)
    [defaults, groups, elements] = @defaults()
    rules = []
    for attribute, meta of condition

      objectAttribute = attribute.split(/\./)

      # get stored params
      if meta && objectAttribute[1]
        operator = meta.operator
        value = meta.value
        model = toCamelCase(objectAttribute[0])
        config = elements[attribute]

        valueHuman = []
        if _.isArray(value)
          for data in value
            r = @humanTextLookup(config, data)
            valueHuman.push r
        else
          valueHuman.push @humanTextLookup(config, value)

        if valueHuman.join
          valueHuman = valueHuman.join(', ')
        rules.push "#{App.i18n.translateContent('Where')} <b>#{App.i18n.translateContent(model)} -> #{App.i18n.translateContent(config.display)}</b> #{App.i18n.translateContent(operator)} <b>#{valueHuman}</b>."

    return [none] if _.isEmpty(rules)
    rules

  @humanTextLookup: (config, value) ->
    return value if !App[config.relation]
    return value if !App[config.relation].exists(value)
    data = App[config.relation].fullLocal(value)
    return value if !data
    if data.displayName
      return App.i18n.translateContent(data.displayName())
    valueHuman.push App.i18n.translateContent(data.name)

  @HasPreCondition: ->
    return true

  @hasEmptySelectorAtStart: ->
    return false

  @hasDuplicateSelector: ->
    return false

  @coreWorkflowCustomModulesActive: ->
    enabled = false
    for workflow in App.CoreWorkflow.all()
      continue if !workflow.changeable
      continue if !workflow.condition_saved['custom.module'] && !workflow.condition_selected['custom.module'] && !workflow.perform['custom.module']
      enabled = true
      break
    return enabled
