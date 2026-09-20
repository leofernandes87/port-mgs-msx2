"""Offline validator for the explicit JSON Schema subset used by this project.

No network refs and no silent acceptance of unsupported schema keywords.
"""
import json
from pathlib import Path
import re

SCHEMA = Path(__file__).resolve().parents[2] / 'data/schemas/extraction.schema.json'
KEYWORDS = {'$schema','$id','$defs','$ref','type','properties','required','additionalProperties',
            'items','minItems','maxItems','minimum','maximum','pattern','enum','const','anyOf'}


def validate(value,schema,root=None,path='$'):
    root=schema if root is None else root
    if set(schema)-KEYWORDS:
        raise ValueError('Unsupported schema keyword')
    if '$ref' in schema:
        parts=schema['$ref'].split('/')
        if parts[:2]!=['#','$defs'] or len(parts)!=3:
            raise ValueError('Only local definition references supported')
        return validate(value,root['$defs'][parts[2]],root,path)
    if 'anyOf' in schema:
        for candidate in schema['anyOf']:
            try:
                validate(value,candidate,root,path)
                return
            except ValueError:
                pass
        raise ValueError(path+': no matching type')
    checks={'integer':lambda x:type(x) is int,'boolean':lambda x:type(x) is bool,
            'string':lambda x:isinstance(x,str),'array':lambda x:isinstance(x,list),
            'object':lambda x:isinstance(x,dict),'null':lambda x:x is None}
    if 'type' in schema and not checks[schema['type']](value):
        raise ValueError(path+': invalid type')
    if 'const' in schema and (type(value) is not type(schema['const']) or value!=schema['const']):
        raise ValueError(path+': invalid constant')
    if 'enum' in schema and not any(type(value) is type(v) and value==v for v in schema['enum']):
        raise ValueError(path+': value outside enum')
    for key,comparison in [('minimum',lambda x,y:x<y),('maximum',lambda x,y:x>y)]:
        if key in schema and comparison(value,schema[key]):
            raise ValueError(path+': value outside bounds')
    if 'pattern' in schema and not re.search(schema['pattern'],value):
        raise ValueError(path+': invalid string pattern')
    if isinstance(value,list):
        if len(value)<schema.get('minItems',0) or len(value)>schema.get('maxItems',len(value)):
            raise ValueError(path+': invalid array length')
        for i,element in enumerate(value):
            validate(element,schema.get('items',{}),root,path+f'[{i}]')
    if isinstance(value,dict):
        if set(schema.get('required',[]))-set(value):
            raise ValueError(path+': missing property')
        properties=schema.get('properties',{})
        for key,element in value.items():
            if key in properties:
                validate(element,properties[key],root,path+'.'+key)
            elif schema.get('additionalProperties') is False:
                raise ValueError(path+': unknown property '+key)
            elif isinstance(schema.get('additionalProperties'),dict):
                validate(element,schema['additionalProperties'],root,path+'.'+key)


def validate_package(package):
    schema=json.loads(SCHEMA.read_text())
    validate(package,schema)
    validate_relations(package)


def validate_relations(package):
    """Cross-references and derived values, independent of schema mechanics."""
    rooms=package['rooms']
    if [x['id'] for x in rooms]!=list(range(251)):
        raise ValueError('Room IDs must be complete and ordered')
    layouts={x['id']:x for x in package['layouts']}
    if len(layouts)!=len(package['layouts']):
        raise ValueError('Duplicate layout ID')
    for room in rooms:
        if room['status']=='decoded':
            if room['layout_ref'] not in layouts or len(room['expanded_tiles'])!=768 or len(room['static_collision'])!=768:
                raise ValueError('Invalid decoded room references/dimensions')
        elif room['layout_ref'] is not None or room['expanded_tiles'] or room['static_collision']:
            raise ValueError('Undefined room contains invented data')
    paths={x['id'] for x in package['paths']}
    for entry in package['room_paths']:
        if not set(entry['ordered_path_refs'])<=paths:
            raise ValueError('Broken path reference')
    for path in package['paths']:
        if path['kind']=='points_yx' and any(not isinstance(v,list) or len(v)!=2 for v in path['values']):
            raise ValueError('Invalid coordinate path')
        if path['kind']=='look_directions_raw' and any(type(v) is not int or not 0<=v<=3 for v in path['values']):
            raise ValueError('Invalid look direction path')
    for key,ids in [('tilesets',range(8)),('collision_profiles',range(7)),('metatile_sets',range(1,7)),('palettes',range(16))]:
        if [x['id'] for x in package[key]]!=list(ids):
            raise ValueError('Invalid ordered IDs: '+key)
    from tools.reverse_engineering.analyze import expand_metatiles
    for room in rooms:
        if room['graphics_set_ref']>=8 or room['palette_ref']>=16:
            raise ValueError('Invalid room graphics/palette reference')
        if room['status']=='decoded':
            meta=room['metatile_set_ref']
            if not 1<=meta<=6 or room['graphics_set_ref']>=7:
                raise ValueError('Invalid room metatile/collision reference')
            definitions=bytes(v for tile in package['metatile_sets'][meta-1]['definitions'] for v in tile)
            expected=list(expand_metatiles(bytes(layouts[room['layout_ref']]['metatile_ids']),definitions))
            if expected!=room['expanded_tiles']:
                raise ValueError('Derived room tiles disagree with compact layout')
            flags=package['collision_profiles'][room['graphics_set_ref']]['movement_blocked_by_tile']
            if [flags[t] for t in expected]!=room['static_collision']:
                raise ValueError('Derived collision disagrees with profile')
    for ts in package['tilesets']:
        if [i for i,tile in enumerate(ts['pixels_by_tile']) if tile is None]!=ts['unloaded_tile_ids']:
            raise ValueError('Unloaded tile metadata disagrees with pixels')
    for door in package['doors']:
        if door['open_rule_id']!=door['open_logic_raw']&31:
            raise ValueError('Door rule does not match original byte')
