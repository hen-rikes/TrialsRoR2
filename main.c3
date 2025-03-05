import rlib;

import std::io;
import std::collections;

struct Tile {
    float[<2>] pos;
    float[<2>] size;
    char *name;
    rlib::Texture2D image;
    uint state;
}

// NOTE: The states currently supported are NORMAL and DONE.
const uint NUM_OF_STATES = 2;

struct Map {
    String key;
    uint value;
}

fn void save_states(List(<Tile>) *tiles, String file_name) {
    File! file = file::open(file_name, "w");
    defer file.close()!!;

    if (catch excuse = file) {
        rlib::trace_log(rlib::LOG_ERROR, "[ERROR] Couldn't open file <%s>", file_name);
        return;
    }

    DString content;
    defer content.free();

    foreach (tile : tiles) {
        content.appendf("%s,%d;", (ZString)tile.name, tile.state);
    }

    file.write(content.copy_str())!!;
    rlib::trace_log(rlib::LOG_INFO, "[INFO] States successfully saved to file <%s>", file_name);
}

fn List(<Map>) load_states(String file_name) {
    File! file = file::open(file_name, "r");
    defer file.close()!!;

    if (catch excuse = file) {
        rlib::trace_log(rlib::LOG_ERROR, "[ERROR] Couldn't open file <%s>", file_name);
        return {};
    }

    usz! num_of_bytes = file::get_size(file_name);
    if (catch excuse = num_of_bytes) {
        rlib::trace_log(rlib::LOG_ERROR, "[ERROR] Couldn't find file <%s>", file_name);
        return {};
    }

    DString word;
    defer word.free();

    List(<Map>) map;
    String key = "";
    uint value = 0;

    for (uint i = 0; i < num_of_bytes; i++) {
        char! c = file.read_byte();
        if (catch excuse = c) {
            rlib::trace_log(rlib::LOG_ERROR, "[ERROR] Couldn't read file <%s>", file_name);

            return {};
        }
        if (c == '\n' || c == '\r') {
            break;
        }

        if (c == ',') {
            key = word.tcopy_str();

            word.clear();
        } else if (c == ';') {
            value = (uint)word.tcopy_str().to_int()!!;
            map.push({ .key = key, .value = value });

            word.clear();
        } else {
            word.append_char(c);
        }
    }

    return map;
}

fn void main() {
    HashMap(<String, String>) artifacts_urls;
    artifacts_urls["Chaos"]         = "https://riskofrain2.fandom.com/wiki/Artifact_of_Chaos";
    artifacts_urls["Command"]       = "https://riskofrain2.fandom.com/wiki/Artifact_of_Command";
    artifacts_urls["Death"]         = "https://riskofrain2.fandom.com/wiki/Artifact_of_Death";
    artifacts_urls["Delusion"]      = "https://riskofrain2.fandom.com/wiki/Artifact_of_Delusion";
    artifacts_urls["Devotion"]      = "https://riskofrain2.fandom.com/wiki/Artifact_of_Devotion";
    artifacts_urls["Dissonance"]    = "https://riskofrain2.fandom.com/wiki/Artifact_of_Dissonance";
    artifacts_urls["Enigma"]        = "https://riskofrain2.fandom.com/wiki/Artifact_of_Enigma";
    artifacts_urls["Evolution"]     = "https://riskofrain2.fandom.com/wiki/Artifact_of_Evolution";
    artifacts_urls["Frailty"]       = "https://riskofrain2.fandom.com/wiki/Artifact_of_Frailty";
    artifacts_urls["Glass"]         = "https://riskofrain2.fandom.com/wiki/Artifact_of_Glass";
    artifacts_urls["Honor"]         = "https://riskofrain2.fandom.com/wiki/Artifact_of_Honor";
    artifacts_urls["Kin"]           = "https://riskofrain2.fandom.com/wiki/Artifact_of_Kin";
    artifacts_urls["Metamorphosis"] = "https://riskofrain2.fandom.com/wiki/Artifact_of_Metamorphosis";
    artifacts_urls["Rebirth"]       = "https://riskofrain2.fandom.com/wiki/Artifact_of_Rebirth";
    artifacts_urls["Sacrifice"]     = "https://riskofrain2.fandom.com/wiki/Artifact_of_Sacrifice";
    artifacts_urls["Soul"]          = "https://riskofrain2.fandom.com/wiki/Artifact_of_Soul";
    artifacts_urls["Spite"]         = "https://riskofrain2.fandom.com/wiki/Artifact_of_Spite";
    artifacts_urls["Swarms"]        = "https://riskofrain2.fandom.com/wiki/Artifact_of_Swarms";
    artifacts_urls["Vengeance"]     = "https://riskofrain2.fandom.com/wiki/Artifact_of_Vengeance";

    int width = 900; 
    int height = 600;

    rlib::set_config_flags(rlib::ConfigFlags.FLAG_WINDOW_RESIZABLE.value);
    rlib::init_window(width, height, "Trials");
    defer rlib::close_window();
    rlib::set_trace_log_level(rlib::LOG_ERROR);

    char *done_image_path = "images/done.png";
    rlib::Texture2D done_image = rlib::load_texture(done_image_path);
    defer rlib::unload_texture(done_image);

    char *open_url_image_path = "images/open_url.png";
    rlib::Texture2D open_url_image = rlib::load_texture(open_url_image_path);
    defer rlib::unload_texture(open_url_image);

    char *artifacts_path = "artifacts";
    FilePathList artifacts_dir = rlib::load_directory_files(artifacts_path);
    defer rlib::unload_directory_files(artifacts_dir);

    String save_file = "states.txt";
    bool save_file_exists = false;
    bool marked_to_save = false;

    uint num_of_tiles = artifacts_dir.count;
    List(<Tile>) tiles;
    defer {
        foreach (tile : tiles) {
            rlib::unload_texture(tile.image);
        }
    }

    uint rez = 5; 
    if (num_of_tiles < rez) rez = num_of_tiles;

    // TODO: find a way to correctly scale tile_size
    float[<2>] tile_size = width*0.123f;
    float[<2>] offset = 40.f;

    float tiles_width = (tile_size.x + offset.x) * rez - 25.f;
    float tiles_height = ((tile_size.y + offset.y) * (float)$$ceil((float)num_of_tiles/(float)rez))-50.f;


    float[<2>] start_pos = { 
        (width * 0.5f) - (tiles_width * 0.5f),
        (height * 0.5f) - (tiles_height * 0.5f),
    };


    List(<Map>) states;
    if (file::is_file(save_file)) {
        save_file_exists = true;
        states = load_states(save_file);
    }

    uint x = 0;
    uint y = 0;
    for (uint i = 1; i < num_of_tiles+1 && artifacts_dir.count != 0; i++) {
        uint state_value_from_file = 0;
        if ((uint)(i-1) >= states.len()) { 
            state_value_from_file = 0;
        } else {
            state_value_from_file = states[(usz)(i-1)].value;
        }

        tiles.push({
            .pos = { x * (tile_size.x + offset.x) + start_pos.x, y * (tile_size.y + offset.y) + start_pos.y },
            .size = tile_size,
            .name = ZString.tcopy((ZString)rlib::get_file_name_without_ext(artifacts_dir.paths[i-1])),
            .image = rlib::load_texture(artifacts_dir.paths[i-1]),
            .state = save_file_exists ? state_value_from_file : 0,
        });

        if (i % rez == 0) {
            x = 0;
            y++;
        } else {
            x++;
        }
    }

    if (!save_file_exists) save_states(&tiles, save_file);

    uint font_size = (uint)(tile_size.x * 0.18f);

    rlib::set_target_fps(60);
    while (!rlib::window_should_close()) {
        width  = rlib::get_screen_width();
        height = rlib::get_screen_height();

        foreach (&tile : tiles) {
            if (rlib::check_collision_point_rec(rlib::get_mouse_position(), { tile.pos.x, tile.pos.y, tile.size.x, tile.size.y })) {
                if (rlib::is_mouse_button_pressed(rlib::MouseButton.MOUSE_BUTTON_LEFT.value)) {
                    marked_to_save = true;
                    tile.state = (tile.state + 1) % NUM_OF_STATES;
                } else if (rlib::is_mouse_button_pressed(rlib::MouseButton.MOUSE_BUTTON_RIGHT.value)) {
                    if (catch rlib::open_url(artifacts_urls[ZString.str_view((ZString)tile.name)])) {
                        rlib::trace_log(rlib::LOG_ERROR, "[INFO] Url not found");
                    }
                }
            }
        }

        rlib::begin_drawing();
        rlib::clear_backgroud(rlib::get_color(0x1c1c1cff));

        foreach(tile : tiles) {
            bool highlighted = false;
            if (rlib::check_collision_point_rec(rlib::get_mouse_position(), { tile.pos.x, tile.pos.y, tile.size.x, tile.size.y })) highlighted = !highlighted;

            rlib::Rectangle tile_dest = { tile.pos, tile.size };
            if (highlighted) {
                float highlighted_increase = 0.125f;
                float[<2>] size_increase = { tile.size.x*highlighted_increase, tile.size.y*highlighted_increase };
                float[<2>] size = {size_increase.x + tile.size.x, size_increase.y + tile.size.y}; 
                float[<2>] pos  = {tile.pos.x - (size_increase.x*0.5f), tile.pos.y - (size_increase.y*0.5f)};
                tile_dest = {pos, size}; 
            }

            // Artifact image
            rlib::draw_texture_pro(tile.image, 
                {{0.f, 0.f}, {tile.image.width, tile.image.height}}, 
                tile_dest,
                {0.f, 0.f}, 
                0.f,
                rlib::WHITE);

            // Outside lines
            rlib::draw_rectange_rounded_lines(tile_dest,
                0.3f, 
                1, 
                2.f, 
                rlib::get_color(0xd2d2d2ff));

            // Artifact name
            rlib::draw_text(tile.name, 
                (CInt)(tile_dest.pos.x+((tile_dest.size.x)*0.5f-(rlib::measure_text((ZString)tile.name, font_size)*0.5f))),
                (CInt)(tile_dest.pos.y+tile_dest.size.y-font_size), 
                (CInt)font_size, 
                rlib::WHITE);

            // Done image
            if (tile.state) {
                float[<2>] final_size = { tile_dest.size.x * 0.28f, tile_dest.size.y * 0.28f };

                rlib::draw_circleV({tile_dest.pos.x+(final_size.x*0.5f)+4.f, tile_dest.pos.y+4.f+(final_size.x*0.5f)}, final_size.x*0.6f, rlib::get_color(0x1c1c1cff));
                rlib::draw_texture_pro(done_image,
                    {{0.f, 0.f}, {done_image.width, done_image.height}},
                    //{pos, size},
                    {{tile_dest.pos.x+4.f, tile_dest.pos.y+4.f}, final_size},
                    {0.f, 0.f},
                    0.f,
                    rlib::WHITE);
            }

            // Open url image
            if (highlighted) {
                float[<2>] final_size = { tile_dest.size.x * 0.28f, tile_dest.size.y * 0.28f };

                rlib::draw_texture_pro(open_url_image, 
                    {{0.f, 0.f}, {open_url_image.width, open_url_image.height}},
                    {{tile_dest.pos.x+tile_dest.size.x-(final_size.x*0.5f)-5.f, tile_dest.pos.y-(final_size.y*0.5f)+5.f}, final_size},
                    {0.f, 0.f},
                    0.f,
                    rlib::WHITE);
            }
        }

        rlib::end_drawing();

        if (marked_to_save) {
            save_states(&tiles, save_file);
            marked_to_save = false;
        }
    }
}
