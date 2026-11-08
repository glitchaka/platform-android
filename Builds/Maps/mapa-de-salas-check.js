
  (() => {
    const root = document.getElementById('ashen-room-map');
    const data = JSON.parse(root.querySelector('[data-world-map]').textContent);
    const byId = new Map(data.rooms.map(room => [room.id, room]));
    const selector = root.querySelector('[data-room-selector]');
    const exits = root.querySelector('[data-exits]');
    const gates = {
      double_jump: 'Requiere doble salto', dash: 'Requiere impulso',
      keys: 'Requiere las dos llaves', postgame: 'Requiere las cinco misiones',
      'boss:bone_lord': 'Requiere vencer al Príncipe de Huesos',
      'boss:royal_spire': 'Requiere vencer al guardián real'
    };
    const access = {
      tutorial: 'Disponible desde el inicio.',
      town: 'Acceso: medalla del cofre del Sendero.',
      cross: 'Acceso: medalla del cofre del Sendero.',
      fungus: 'Campaña: vence al Nido y cobra al guía. Postgame: completa Rutas del Alba.',
      bone: 'Campaña: consigue el doble salto. Postgame: completa Semillas de Vida.',
      city: 'Campaña: recoge la llave de Huesos. Postgame: completa Deuda de Huesos.',
      palace: 'Campaña: impulso y llave real. Postgame: completa Forja de la Ciudad.',
      aurora: 'Acceso: completa las cinco misiones; entrada desde el Trono.'
    };
    for (const [id,zone] of Object.entries(data.zones)) {
      const group = document.createElement('optgroup'); group.label = zone.name;
      for (const room of data.rooms.filter(r => r.zone === id)) {
        const option = document.createElement('option'); option.value = room.id;
        option.textContent = room.name; group.appendChild(option);
      }
      selector.appendChild(group);
    }
    function render(id) {
      const room = byId.get(id); selector.value = id;
      root.querySelector('[data-zone]').textContent = data.zones[room.zone].name;
      root.querySelector('[data-room-name]').textContent = room.name;
      exits.replaceChildren();
      for (const door of room.doors) {
        const destination = byId.get(door.to);
        const branch = document.createElement('div'); branch.className = 'room-exit';
        const stem = document.createElement('div'); stem.className = 'room-stem'; stem.setAttribute('aria-hidden','true');
        const side = document.createElement('span'); side.className = 'text-small'; side.textContent = 'Portal ' + door.number + ': ' + door.side.toLocaleLowerCase('es');
        const button = document.createElement('button'); button.type = 'button'; button.className = 'btn';
        button.textContent = destination.name; button.addEventListener('click', () => render(destination.id));
        const back = destination.doors.find(exit => exit.to === room.id);
        const gate = document.createElement('span'); gate.className = 'text-small'; gate.textContent = 'Llegada: portal ' + back.number + '. ' + (gates[door.gate] || data.zones[destination.zone].name);
        branch.append(stem,side,button,gate); exits.appendChild(branch);
      }
      let detail = access[room.zone] || (room.id === 'deep_west' ? access.fungus : access.city);
      if (room.reward === 'double_jump' || room.reward === 'dash') {
        detail += ' Cofre en la plataforma más alta: ' + (room.reward === 'dash' ? 'impulso.' : 'doble salto.');
        if (room.lever) detail += ' Activa antes la palanca de la primera plataforma.';
      } else if (room.reward === 'rest') detail += ' Tiene descanso y tienda.';
      else if (room.reward === 'boss') detail += ' Sala de guardián y cofre.';
      root.querySelector('[data-room-detail]').textContent = detail;
    }
    selector.addEventListener('change', () => render(selector.value));
    render('reservoir');
  })();
  