/**
 *  Tmor Da Macro
 *  Author: Yimo Jiang
 *  Description: 
 */
model Macro


global
{
// GIS files input
	file shape_file_buildings <- shape_file('../includes/1979-all-3d/1979-all-3d.shp', 0) parameter: 'Initial building shapefile';
	string type_feature <- 'LAYER' parameter: 'FEATURE name for building type';
	string obj_feature <- 'SHAPENAME' parameter: 'FEATURE name for building OBJ filename';
	string obj_file_location <- '../includes/obj/' parameter: 'Location for .OBJ files';
	file shape_file_roads <- shape_file('../includes/gis-2016-streets/gis-2016-pathways.shp', 0) parameter: 'Road shapefile';
	file color_map_file <- csv_file('../includes/color.csv');

	// experiment parameters
	int initial_population <- 1200 parameter: 'Initial population';
	int population_growth <- 3 min: 0 max: 100 parameter: 'Population growth rate (%)';
	float space_per_person <- 9.0 parameter: 'Space for each person at home (sqm)';
	float par_unit_x <- 3.0 parameter: 'Width of new units';
	float par_unit_y <- 3.0 parameter: 'Height of new units';
	float unit_z <- 3.0 parameter: 'Depth of new units';
	int build_time <- 2 parameter: 'Time needed for building a unit';
	int build_probability <- 100 parameter: 'Probability for a new unit to be built (%)';
	int max_storeys <- 5 parameter: 'Maximum number of storeys';
	float distance_between_units <- 0 parameter: 'Distance between two neighbor units';
	int max_unit_per_cycle <- 10 parameter: 'Maximum possible number of units build at a time';
	float shop_distance_to_road <- 20 parameter: 'Max distance between the road/path and a shop';
	int iteration_one <- 1979 parameter: 'Year to begin T1';
	int iteration_two <- 1989 parameter: 'Year to begin T2';
	int iteration_three <- 1999 parameter: 'Year to begin T3';
	int iteration_four <- 2009 parameter: 'Year to begin T4';
	int stop_year <- 2016 parameter: 'Year to stop simulation';
	int days_per_cycle <- 7 min: 1 max: 360 parameter: 'Number of days represented by one cycle';
	string result_output <- '../results'; //parameter: 'Folder to save the output';
	int prob_to_shop <- 20 min: 0 max: 100 parameter: 'Probability for home turn into shop';
	int orphanage_distance <- 50 parameter: 'Max distance between orphanage and wat to turn into orphanage';
	int prob_to_orphanage <- 15 parameter: 'Probability for home turn into orphanage';
	date starting_date <- date([iteration_one, 1, 1]);
	bool skip_ground;
	// track the population data with growth every cycle
	int total_population;
	int population_new_year;
	int total_capacity;

	// set the display boundary to be the envelope of the roads
	geometry shape <- envelope(shape_file_roads);
	// color for differnet buildings
	map<string, rgb> colorMap;

	// types to count the area when updating stats
	list<string> types_area <- [string(home), string(shop), string(greens), string(temple), string(church), string(orphanage)];

	// store the quantified data for each type of buildings
	map<string, float> count_area;
	map<int, int> count_storey;
	// the graph for the roads
	graph road_graph;
	map<paths, float> weights_map;

	// time represented by each cycle
	float step <- days_per_cycle # day;
	int current_iteration <- 1;
	bool occupiable_available <- true;
	bool ground_available <- true;

	// writing results to text for analysis
	matrix results;
	list<string> results_header;
	int results_rows;
	int results_columns;
	string
	results_footer <- 'Initial population: ' + initial_population + "," + 'Population Growth: ' + population_growth + "," + 'Space per person: ' + space_per_person + "," + 'Time to build: ' + build_time + "," + 'Build possibility' + build_probability + "," + 'Max storeys: ' + max_storeys + "," + 'Distance between units: ' + distance_between_units + "," + 'Max units per cycle: ' + max_unit_per_cycle + "," + 'Shop distance to road: ' + shop_distance_to_road + "," + 'Days per cycle' + days_per_cycle + "," + 'Probability turn to shop: ' + prob_to_shop + "," + 'Orphanage distance' + orphanage_distance + "," + 'Probability turn to orphanage' + prob_to_orphanage;
	int results_prefix;
	bool new_year <- true update: current_date.month = 1 and current_date.day <= days_per_cycle;

	// for scenario 2
	float init_occupiable;
	float occupied_area;
	bool randomized;
	int num_init;
	list<agent> cannot_overlap <- [] update: (agents of_generic_species building) + (agents of_generic_species road);

	//for scenario 3
	int percent_shop_random <- 50;
	bool skip_shop;
	// keep the initial orphanage to improve performance for homes
	orphanage old_orphanage;
	float old_orphanage_west;
	float old_orphanage_south;

	// used by batch mode, just so there are less experimenets to run
	float unit_xy <- 0;
	float unit_x <- unit_xy > 0 ? unit_xy : par_unit_x;
	float unit_y <- unit_xy > 0 ? unit_xy : par_unit_y;
	int running_scenario <- 1;
	bool is_batch;
	bool output_scenario;
	// in case old orphanage gets wiped out or ran out of space
	bool failed;

	// I don't know why I couldn't cast machine time to string directly, so...
	init
	{

	// initialize the population data
		total_population <- initial_population;
		population_new_year <- total_population;
		count_area <- [];
		loop t over: types_area
		{
			add t::0 to: count_area;
		}

		loop i from: 1 to: max_storeys
		{
			add i::0 to: count_storey;
		}

		// initialize results header
		results_columns <- 3 + length(count_area) + length(count_storey.keys);
		// total number of years + 2 rows for header and footer
		results_rows <- stop_year - iteration_one + 3;
		results_header <- ['Date', 'Population', 'Capacity'];
		loop i over: count_area.keys
		{
			add i to: results_header;
		}

		loop i over: count_storey.keys
		{
			add string(i) to: results_header;
		}

		results <- results_header as_matrix ({ results_columns, results_rows });
		results[0, results_rows - 1] <- results_footer;
		// load the color map 
		matrix colorMapFile <- matrix(color_map_file);
		loop i from: 0 to: colorMapFile.rows - 1
		{
			add string(colorMapFile[0, i])::rgb(int(colorMapFile[1, i]), int(colorMapFile[2, i]), int(colorMapFile[3, i])) to: colorMap;
		}

		do load_pathway(1);

		// create the initial bulidings from the shapefile
		create unit_factory from: shape_file_buildings with: [type:: string(get(type_feature)), shape_obj::string(get(obj_feature)), is_base::string(get('BASE'))];

		// get the initial occupiable area, only used by Random model
		ask agents of_generic_species occupiable
		{
			float member_area;
			ask members
			{
				member_area <- member_area + self.shape.area;
			}

			init_occupiable <- init_occupiable + member_area;
		}

		old_orphanage <- first(orphanage where (each.shape.area = max_of(orphanage, each.shape.area)));
		old_orphanage_west <- min_of(old_orphanage.shape.points, each.location.x);
		old_orphanage_south <- max_of(old_orphanage.shape.points, each.location.y);
		ask home where (each.location.z = 0 and each distance_to old_orphanage <= orphanage_distance and each distance_to (wat closest_to each) <= orphanage_distance

		// make sure it goes to the right side, although we don't know why it's going to that side
		and each.location.x > old_orphanage_west)
		{
			self.orphanage_potential <- true;
		}

		// initialize statistics
		do update_stats;
		do update_results;
	}

	reflex update when: !new_year
	{
	// population increase 
		float new_people <- (population_new_year * (population_growth / 100)) / (360 / days_per_cycle);
		float expected_population <- population_new_year + new_people * (((time / # day) mod 360) / days_per_cycle);
		if total_population < expected_population
		{
		// can't increase a quater of a person so increase by one instead with 50% chance
			if new_people < 1
			{
				new_people <- flip(0.5) ? 1.0 : 0;
			}

			total_population <- total_population + int(new_people);
		}

		// run scenarios
		if running_scenario = 1
		{
			do scenario_one;
		} else if running_scenario = 2
		{
			do scenario_two;
		} else if running_scenario = 3
		{
			do scenario_three;
		}

	}

	reflex new_year when: new_year
	{
		if current_date.year = iteration_one
		{
			if running_scenario = 3
			{
				list<grids> shop_potential <- grids where (!empty(boundary overlapping each) and (roads closest_to each) distance_to each <= (unit_x > unit_y ? unit_y : unit_x) and (roads
				closest_to each) distance_to each > 1 and empty((agents of_generic_species building) overlapping each));
				int num_grids <- length(shop_potential);
				loop i from: 0 to: round(num_grids * (percent_shop_random / 100))
				{
					ask one_of(shop_potential)
					{
						create unit_factory with: [type:: string(shop), location::self.location, shape::rectangle({ unit_x, unit_y })];
					}

				}

			}

		}

		if dead(old_orphanage)
		{
			failed <- true;
			// gama destroyed the orphanage somewhat, this experiment is no longe valid
			write "Old orphanaged wiped by school, model failed!";
			if is_batch
			{
				string machine_time_string <- string(int(floor(machine_time / 1000000))) + string(int(machine_time - floor(machine_time / 1000000) * 1000000));
				string output_dir <- '';
				if output_scenario
				{
					output_dir <- result_output + string(running_scenario) + '/';
				} else if running_scenario = 1
				{
					output_dir <- result_output + '/unit_' + unit_xy + '_space_' + space_per_person + '_percycle_' + max_unit_per_cycle + '/';
				} else if running_scenario = 2
				{
					output_dir <- result_output + '/random_' + num_init;
				}

				string output_name <- '_failed_' + machine_time_string;
				string temp_name <- output_name;
				results_prefix <- 0;
				loop while: file_exists(output_dir + temp_name)
				{
					results_prefix <- results_prefix + 1;
					temp_name <- string(results_prefix) + '_' + output_name;
				}

				output_name <- temp_name;
				save '' to: output_dir + output_name type: text;
				do halt;
			} else
			{
				do pause;
			}

		}

		// make the population up to the expected population 
		int target_population <- round(population_new_year * (1 + (population_growth / 100)));
		total_population <- total_population > target_population ? total_population : target_population;
		population_new_year <- total_population;

		// homes may turn into orphanage every year
		ask home where (each.z = 0 and each.can_build_on_top and each.orphanage_potential)
		{
			do turn_into_orphanage;
		}

		// save output data every year
		do update_results;
		if is_batch and current_date.year >= stop_year
		{
			do batch_mode_save;
			do halt;
		} else if current_date.year >= stop_year
		{
		// save the results and stop
			string machine_time_string <- string(int(floor(machine_time / 1000000))) + string(int(machine_time - floor(machine_time / 1000000) * 1000000));
			string output_name <- result_output + "/" + machine_time_string;
			save results to: output_name + '.csv' type: "csv";
			save agents of_generic_species (building) to: '2016_building.shp' type: shp with: [type:: 'Type', shape_obj::'OBJ', height::'Height', z::'Z', is_base::'Base'];
			if !empty(agents of_generic_species (surface))
			{
				save agents of_generic_species (surface) to: '2016_surface.shp' type: shp with: [type:: 'Type', shape_obj::'OBJ', height::'Height', is_base::'Base'];
			}

			save boundary to: '2016_boundary.shp' type: shp;
			do pause;
		}

	}

	// introduce pathways and turn some homes into shops
	reflex start_T2 when: current_date.year = iteration_two and current_date.day <= days_per_cycle and current_date.month = 1
	{
		do load_pathway(2);
		ask home where (each.surrounding_populated)
		{
			do turn_into_shop;
		}

	}
	// introduce pathways and turn some homes into shops
	// also introduce school and wipe out whatever being there	
	reflex start_T3 when: current_date.year = iteration_three and current_date.day <= days_per_cycle and current_date.month = 1
	{
		ask agents of_generic_species road where (each.destroy = 3)
		{
			do die;
		}

		do load_pathway(3);

		// load school
		loop b over: shape_file_buildings
		{
			string building_type <- string(b get (type_feature));
			if building_type contains 'school'
			{
				create unit_factory with: [shape::b, type:: building_type, shape_obj::string(b get (obj_feature)), is_base::string(b get ('BASE'))];
			}

		}

		ask home
		{
			do turn_into_shop;
		}

	}

	// introduce pathways and turn some homes into shops
	reflex start_T4 when: current_date.year = iteration_four and current_date.day <= days_per_cycle and current_date.month = 1
	{
		do load_pathway(4);
		ask home
		{
			do turn_into_shop;
		}

	}

	action load_pathway (int t)
	{
	// create paths from the shapefile
	// loop through the paths to load only the ones tagged with the appropriate iteration
		loop path_shape over: shape_file_roads
		{
			int introduce <- int(path_shape get 'INTRODUCE');
			if introduce = t
			{
				create unit_factory with: [shape::path_shape, type:: path_shape get type_feature, introduce::introduce, destroy::int(path_shape get 'DESTROY')];
			}

		}

	}

	action build_home (building base, point new_location)
	{
		geometry new_shape;
		if base != nil
		{
			new_shape <- base.shape;
		} else
		{
			new_shape <- rectangle({ unit_x, unit_y });
		}

		create unit_factory with: [type:: string(home), location::new_location, shape::new_shape];
	}

	point expand_home
	{
		point available_space;
		list<home> possible_home <- home where (!each.surrounding_populated);
		loop while: available_space = nil and !skip_ground
		{
			if !empty(possible_home)
			{
				ask first(shuffle(possible_home))
				{

				// check the neighbor grids that are not overlapping with anything
					list<grids> available_neighbor <- self.neighbors where (cannot_overlap overlapping each = []);
					if !empty(available_neighbor)
					{
						available_space <- first(shuffle(available_neighbor)).location;
						break;
					}

					// check if the expansion is blocked by a path, if so, jump over
else if !empty(neighbor_paths)
					{
						loop n over: neighbor_paths
						{
						//if (roads closest_to n) distance_to n = 0 {
							list<grids> available_across <- n.neighbors where (cannot_overlap overlapping each = []);
							if !empty(available_across)
							{
								available_space <- first(shuffle(available_across)).location;
								break;
							}
							//}
						}

						if available_space = nil
						{
							self.surrounding_populated <- true;
							possible_home <- home where (!each.surrounding_populated);
						}

					}
					// this home is not expandable
else
					{
						self.surrounding_populated <- true;
						possible_home <- home where (!each.surrounding_populated);
					}

				}

			} else
			{
				skip_ground <- true;
			}

		}
		//write "returning available "+available_space;
		return available_space;
	}

	action build_on_top
	{
		building base <- shuffle(home + shop) first_with (each.can_build_on_top);
		if base != nil
		{
			if !([string(home), string(shop)] contains string(species(base)))
			{
				write "building on something wrong: " + base;
			}

			do build_home(base, base.location + { 0, 0, unit_z });
		} else
		{
			write "Run out of sapce!";
			failed <- true;
			if is_batch
			{
				string machine_time_string <- string(int(floor(machine_time / 1000000))) + string(int(machine_time - floor(machine_time / 1000000) * 1000000));
				string output_dir <- '';
				if output_scenario
				{
					output_dir <- result_output + string(running_scenario) + '/';
				} else if running_scenario = 1
				{
					output_dir <- result_output + '/unit_' + unit_xy + '_space_' + space_per_person + '_percycle_' + max_unit_per_cycle + '/';
				} else if running_scenario = 2
				{
					output_dir <- result_output + '/random_' + num_init;
				}

				string output_name <- 'out_of_space_' + machine_time_string;
				string temp_name <- output_name;
				results_prefix <- 0;
				loop while: file_exists(output_dir + temp_name)
				{
					results_prefix <- results_prefix + 1;
					temp_name <- string(results_prefix) + '_' + output_name;
				}

				output_name <- temp_name;
				save '' to: output_dir + output_name type: text;
				do halt;
			} else
			{
				do pause;
			}

		}

	}

	action update_stats
	{
	// TODO: define the appropriate statistics
		loop t over: types_area
		{
			float total_area;
			list<unit> units <- list<unit> (agents of_species (species(t)));
			//write buildings;
			if !empty(units)
			{
				ask units
				{
				//write self.capacity;
					total_area <- total_area + self.floor_area;
					count_area[t] <- total_area;
				}

			} else
			{
				count_area[t] <- 0;
			}

		}

		// count the total capacity of homes
		int current_capacity;
		loop h over: home
		{
			ask h
			{
				current_capacity <- current_capacity + self.capacity;
			}

		}

		total_capacity <- current_capacity;

		// count the number of home at each storey 
		loop k over: count_storey.keys
		{
			if k = max(count_storey.keys)
			{
				count_storey[k] <- count(home, each.location.z >= (k - 1) * unit_z);
			} else
			{
				count_storey[k] <- count(home, each.location.z = (k - 1) * unit_z);
			}

		}

	}

	action update_results
	{
	//['Date','Population','Capacity'];
		int matrix_row <- current_date.year - iteration_one + 1;
		results[0, matrix_row] <- current_date.year;
		results[1, matrix_row] <- total_population;
		results[2, matrix_row] <- total_capacity;
		loop i from: 3 to: 3 + length(count_area) - 1
		{
			results[i, matrix_row] <- count_area[results_header[i]];
		}

		loop i from: 3 + length(count_area) to: results_columns - 1
		{
			results[i, matrix_row] <- count_storey[int(results_header[i])];
		}

	}

	action batch_mode_save
	{
		string machine_time_string <- string(int(floor(machine_time / 1000000))) + string(int(machine_time - floor(machine_time / 1000000) * 1000000));
		string output_dir <- '';
		if output_scenario
		{
			output_dir <- result_output + string(running_scenario) + '/';
		} else if running_scenario = 1
		{
			output_dir <- result_output + '/unit_' + unit_xy + '_space_' + space_per_person + '_percycle_' + max_unit_per_cycle + '/' + machine_time_string + '/';
		} else if running_scenario = 2
		{
			output_dir <- result_output + '/random_' + num_init;
		}

		string output_name <- 'results.csv';
		results_prefix <- 0;
		string temp_name <- output_name;
		loop while: file_exists(output_dir + temp_name)
		{
			results_prefix <- results_prefix + 1;
			temp_name <- string(results_prefix) + '_' + output_name;
		}

		output_name <- temp_name;
		save results to: output_dir + output_name type: "csv";
		if results_prefix = 0
		{
			save agents of_generic_species (building) to: output_dir + '2016_building.shp' type: shp with: [type:: 'Type', shape_obj::'OBJ', height::'Height', z::'Z', is_base::'Base'];
			if !empty(agents of_generic_species (surface))
			{
				save agents of_generic_species (surface) to: output_dir + '2016_surface.shp' type: shp with: [type:: 'Type', shape_obj::'OBJ', height::'Height', is_base::'Base'];
			}

			save boundary to: output_dir + '2016_boundary.shp' type: shp;
		} else
		{
			save agents of_generic_species (building) to: output_dir + results_prefix + '_2016_building.shp' type: shp with:
			[type:: 'Type', shape_obj::'OBJ', height::'Height', z::'Z', is_base::'Base'];
			if !empty(agents of_generic_species (surface))
			{
				save agents of_generic_species (surface) to: output_dir + results_prefix + '_2016_surface.shp' type: shp with:
				[type:: 'Type', shape_obj::'OBJ', height::'Height', is_base::'Base'];
			}

			save boundary to: output_dir + results_prefix + '_2016_boundary.shp' type: shp;
		}

	}
	// Random model only
	float percent_occupied
	{
		return occupied_area / init_occupiable;
	}

	// -------------------- different scenarios -------------------//
	action scenario_one
	{
	// live happily if everyone has a place to live in
	// otherwise, build something on an even week
		if total_population > total_capacity and time mod (build_time * days_per_cycle # day) = 0 and rnd(100) < build_probability
		{
		// build a random number of units
			loop i from: 0 to: rnd(max_unit_per_cycle)
			{
				if !skip_ground
				{

				// fill in temple and church first
					list<occupiable> occupiable_buildings <- list(agents) of_generic_species occupiable where (!empty(each.members));
					if !empty(occupiable_buildings)
					{
						ask first(shuffle(occupiable_buildings))
						{
						//write self;
							release first(shuffle(self.members)) as: home in: world returns: new_home;
							floor_area <- floor_area - (new_home at 0).shape.area;
							occupied_area <- occupied_area + (new_home at 0).shape.area;
							ask new_home
							{
								self.type <- string(home);
							}

						}

					}
					// no more temple or church to fill in
else
					{
					// expand from one of the existing homes
						point available_space <- world.expand_home();
						if available_space != nil and available_space != { 0, 0, 0 }
						{
							ask world
							{
								do build_home(nil, available_space);
							}

						} else
						{
						// no more expandable ground units, skip ground check from now on
							skip_ground <- true;
						}

					}

				} else
				{
					do build_on_top;
				}

				// process the same number of shop / expansion to speed it up
				if flip(prob_to_shop / 100)
				{
					ask shuffle(home) first_with (each.shop_potential and each.surrounding_populated)
					{
						do turn_into(self, string(shop));
					}

				}
				// turn a home next to the main road to shop, only turn into shop when it can't expand anymore
				if flip(prob_to_shop / 100)
				{
					ask shuffle(shop) first_with (each.can_expand)
					{
						do expand;
					}

				}

			}

		}

		do update_stats;
	}

	action scenario_two
	{
		if !randomized
		{
			float occupied;
			occupied <- occupied_area / init_occupiable;
			if occupied >= 0.5
			{
				randomized <- true;
				list<grids> available_grids <- grids where (boundary overlapping each != [] and cannot_overlap overlapping each = []);
				loop i from: 0 to: num_init - 1
				{
					point available_space <- one_of(available_grids).location;
					if available_space != nil
					{
						write "Building at " + string(available_space);
						do build_home(nil, available_space);
					}

				}

			}

		}

		do scenario_one;
	}

	action scenario_three
	{
		if total_population > total_capacity and time mod (build_time * days_per_cycle # day) = 0 and rnd(100) < build_probability
		{
		// build a random number of units
			loop i from: 0 to: rnd(max_unit_per_cycle)
			{
				if !skip_ground
				{
					if !skip_shop
					{
						list<shop> expandable_shop <- shop where (!each.surrounding_populated and (roads closest_to each) distance_to each <= shop_distance_to_road);
						//write expandable_shop;
						point available_space;
						// try to expand from shops first, but not necessarily happen
						if !empty(expandable_shop)
						{
							loop s over: expandable_shop
							{
								list<point> closest_points <- (roads closest_to self).shape.points;
								list<grids> available_neighbors;
								available_neighbors <- s.neighbors where (empty(cannot_overlap overlapping each) and !empty(boundary overlapping each));
								if !empty(available_neighbors)
								{
									available_space <- one_of(available_neighbors).location;
									break;
								} else
								{
									s.surrounding_populated <- true;
								}

							}

						}

						//write available_space;
						if available_space != nil
						{
							do build_home(nil, available_space);
						} else
						{
							skip_shop <- true;
						}

					}
					//list<agent> cannot_overlap <- (agents of_generic_species building) + (agents of_generic_species road);
else
					{
					// expand from one of the existing homes
						point available_space <- world.expand_home();
						if available_space != nil and available_space != { 0, 0, 0 }
						{
							ask world
							{
								do build_home(nil, available_space);
							}

						} else
						{
						// no more expandable ground units, skip ground check from now on
							skip_ground <- true;
						}

					}

				} else
				{
					do build_on_top;
				}
				// turn a home next to the main road to shop, only turn into shop when it can't expand anymore
				if flip(prob_to_shop / 100)
				{
					ask shuffle(shop) first_with (each.can_expand)
					{
						do expand;
					}

				}

			}

		}

		do update_stats;
	}

}

// back ground CA type agents
grid grids cell_width: unit_x + distance_between_units / 2 cell_height: unit_y + distance_between_units / 2 neighbors: 4 schedules: []
{
}

// agent factory
species unit_factory schedules: []
{
	string type;
	string shape_obj;
	float height;
	string is_base;
	int destroy;
	int introduce;
	init
	{
	//write "creating "+type;
	// translate type to species
		if type contains 'green'
		{
			create greens returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'wat'
		{
			create wat returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'temple'
		{
			create temple returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'orphanage'
		{
			create orphanage returns: new_unit;
			do create_new(new_unit at 0);
		}
		//		else if type contains 'institute'
		//		{
		//			create institute returns: new_unit;
		//			do create_new(new_unit at 0);
		//		} 
else if type contains 'church'
		{
			create church returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'cemetary'
		{
			create cemetery returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'home'
		{
			create home returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'school' and current_date.year >= iteration_three
		{
			create school returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'shop'
		{
			create shop returns: new_unit;
			do create_new(new_unit at 0);
		}
		//		else if type contains 'void' {
		//			create void returns:new_unit;
		//			do create_new(new_unit at 0);
		//		}
else if type contains 'path'
		{
			create paths returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'road'
		{
			create roads returns: new_unit;
			do create_new(new_unit at 0);
		} else if type contains 'boundary'
		{
			create boundary returns: new_unit;
			do create_new(new_unit at 0);
		} else
		{
			do die;
		}

	}

	action create_new (unit new)
	{
		create species_of(new) with: [location::self.location, shape::self.shape, shape_obj::self.shape_obj, height::self.height, is_base::self.is_base = 'Y' ?
		true : false, introduce::self.introduce, destroy::self.destroy, type:: self.type];
		ask new
		{
			do die;
		}

		do die;
	}

}

species unit schedules: []
{
	float floor_area;
	string type;
	string shape_obj;
	rgb color;
	float height;
	bool is_base;
	int destroy;
	int introduce;
	bool surrounding_populated;
	init
	{
		type <- string(species(self));
		color <- colorMap[type];
		floor_area <- self.shape.area;
	}

	// change to another type of unit	
	action turn_into (unit source, string target)
	{
		create unit_factory with: [location::source.location, type:: target, shape::source.shape, shape_obj::source.shape_obj, height::source.height, is_base::source.is_base ?
		'Y' : 'N', introduce::self.introduce, destroy::self.destroy];
		do die;
	}

}

// polygon of mainroad
species boundary parent: unit schedules: []
{
	aspect default
	{
		draw shape;
	}

}

species building parent: unit schedules: []
{
//pair<float, point> rotate_degree;
	bool can_build_on_top;
	int capacity;

	//	float x;
	//	float y;
	float z;
	init
	{
		if height = 0 and !is_base
		{
			height <- unit_z;
		}
		//x <- location.x;
		//y <- location.y;
		z <- location.z;

		/*
		if shape_obj != nil and shape_obj != '' and isInitial {
			file shape_obj_file <- obj_file(obj_file_location+shape_obj);
			shape <- rotated_by(geometry(shape_obj_file),-90,{1,0,0})
				at_location location;
			location <- location + {0,0,6};
		}*/
		capacity <- int(floor(shape.area / space_per_person));
	}

	aspect default
	{
		draw shape color: color border: color depth: height;
	}

}

species surface parent: unit schedules: []
{
	init
	{
		height <- 0.0;
	}

	aspect default
	{
		draw shape color: color border: color depth: height;
	}

}

species road parent: unit schedules: []
{
	init
	{
		color <- # black;
		do destruct;
	}

	action destruct
	{
		ask (world.agents of_generic_species building) where (self crosses each)
		{
			if !is_base
			{
				do die;
			}

		}

		//-greens-boundary-paths-roads-grids-church-temple
	}

}

species occupiable parent: building schedules: []
{
	list<geometry> base_units;
	//float available_area;
	list<base_unit> split_units;
	init
	{
	//available_area <- self.shape.area;
		do split_unit;
		do capture_unit;
	}

	action split_unit
	{
	// split the building to create base_units
		if shape.area > unit_x * unit_y
		{
			base_units <- to_rectangles(self, { unit_x, unit_y });
			if base_units != []
			{
				create base_unit from: base_units returns: units;
				remove base_unit where (each.capacity < 1) all: true from: units;
				remove base_unit where ((paths closest_to each) distance_to each = 0) all: true from: units;
				split_units <- units;
			}

		}

	}

	action capture_unit
	{
	}

}

species church parent: occupiable schedules: []
{
	action capture_unit
	{
		if split_units != []
		{
			capture split_units as: church_base;
		}

	}

	species church_base parent: base_unit
	{
	}

}

species temple parent: occupiable schedules: []
{
	action capture_unit
	{
		if split_units != []
		{
			capture split_units as: temple_base;
		}

	}

	species temple_base parent: base_unit
	{
	}

}

species base_unit parent: home
{
}

//// footprints for possible building locations and shapes
//species void
//{
//}
species expandable parent: building
{
	list<grids> neighbors;
	list<grids> neighbor_paths;
	init
	{
		if location.z = 0
		{
			neighbors <- ((grids overlapping self) at 0).neighbors;
			loop n over: neighbors
			{
				if !empty(paths where (each crosses n))
				{
					add n to: neighbor_paths;
				}

			}

			can_build_on_top <- true;
		} else
		{
			list<building> same_building <- list(home + shop) where (each.location.x = self.location.x and each.location.y = self.location.y);
			ask same_building
			{
				self.can_build_on_top <- false;
			}

		}

		can_build_on_top <- self.location.z < unit_z * (max_storeys - 1);
	}

}

species home parent: building schedules: []
{
//int population;
	list<grids> neighbors;
	list<grids> neighbor_paths;
	//bool surrounding_populated;
	bool shop_potential;
	bool orphanage_potential;
	init
	{
		if location.z = 0
		{
			if old_orphanage != nil and location.z = 0 and self distance_to old_orphanage <= orphanage_distance and self distance_to (wat closest_to self) <= orphanage_distance

			// make sure it goes to the right side, although we don't know why it's going to that side
			and location.x > old_orphanage_west
			{
				orphanage_potential <- true;
			}
			// reduce the overlapping green area  for stats
			list<greens> ground_greens <- greens overlapping self;
			if !empty(ground_greens)
			{
				ask ground_greens
				{
					self.floor_area <- self.floor_area - myself.floor_area;
				}

			}

			neighbors <- (first(grids overlapping self)).neighbors where (!empty(boundary overlapping each));
			loop n over: neighbors
			{
				if count(paths, each crosses n) > 0 and count(roads, each crosses n) = 0
				{
					add n to: neighbor_paths;
				}

			}
			// if located next to the main road, it can potentially turn into a shop
			shop_potential <- count(roads, (each distance_to self <= (unit_x > unit_y ? unit_y : unit_x)) and location.z = 0) > 0;
			can_build_on_top <- true;
		} else
		{
			list<building> same_building <- list(home + shop) where (each.location.x = self.location.x and each.location.y = self.location.y);
			ask same_building
			{
				self.can_build_on_top <- false;
			}

		}

		can_build_on_top <- self.location.z < unit_z * (max_storeys - 1);
	}

	//	reflex update {
	//		if surrounding_populated and !shop_potential {
	//			schedulable <- false;
	//		} 
	//	}
	action turn_into_shop
	{
		if (paths closest_to self) distance_to self <= (unit_x > unit_y ? unit_y : unit_x) and flip(prob_to_shop / 100) and self.location.z = 0
		{
			do turn_into(self, string(shop));
		}

	}

	action turn_into_orphanage
	{
	// only ground homes can turn into orphanage
	// only for single storey units
		if rnd(100) < prob_to_orphanage
		{
			do turn_into(self, string(orphanage));
		}

	}

}

//species institute parent: building
//{
//}
species orphanage parent: building schedules: []
{
	init
	{
		can_build_on_top <- false;
	}

}

species shop parent: expandable schedules: []
{
	bool can_expand;
	init
	{
		can_build_on_top <- true;
		roads closest_road <- roads closest_to self;
		if closest_road distance_to self <= shop_distance_to_road
		{
			can_expand <- true;
		}

	}

	// expand when close to main road with a possiblity
	action expand
	{
		list<grids> neighbors <- count(grids, each overlaps self) = 0 ? [] : first(grids overlapping self).neighbors;
		list<home> neighbor_homes;
		loop n over: neighbors
		{
		// only take ground
			neighbor_homes <- (home overlapping n) where (each.location.z = 0 and each.surrounding_populated);
			if !empty(neighbor_homes)
			{
				ask first(shuffle(neighbor_homes))
				{
					do turn_into(self, string(shop));
					break;
				}

			}

		}

		if empty(neighbor_homes)
		{
			can_expand <- false;
		}

	}

}

species school parent: building schedules: []
{
	init
	{
		do destruct;
	}

	action destruct
	{
	//ask (world.agents-boundary-paths-roads-grids-temple-self) where (
	//	self distance_to each = 0
	//) {
	//	do die;
	//}
		ask ((world.agents of_generic_species building) - school + world.agents of_generic_species surface) where (self distance_to each = 0)
		{
			if !is_base
			{
				do die;
			}

		}

	}

}

species cemetery parent: building
{
	init
	{
		height <- 0.0;
	}

}

species roads parent: road schedules: []
{
}

species paths parent: road schedules: []
{
}

species greens parent: surface
{
	reflex
	{
		if floor_area <= 0
		{
			do die;
		}

	}

}

species wat parent: building schedules: []
{
}

experiment 'Scenarios' type: gui
{
	parameter "Running scenario" var: running_scenario <- 1;

	// scenario 2 only 
	parameter "(S2 only) Random units" var: num_init <- 10;
	// scenario 3 only
	parameter "(S3 only) Init shop percent" var: percent_shop_random <- 50;
	output
	{
		display map type: opengl
		{
		//species boundary;
			species greens;
			species church transparency: 0.5;
			species temple transparency: 0.5;
			//species institute;
			species orphanage;
			species wat;
			species cemetery;
			species school;
			agents "ground_home" value: home where (each.location.z = 0);
			agents "other_home" value: home where (each.location.z > 0);
			species shop;
			species roads;
			species paths;
			graphics 'display_date'
			{
				draw string(current_date) at: { 10, 10 } color: # black;
			}

		}

		display "floor_area" type: java2D
		{
			chart "Floor Area of Units" type: series x_serie_labels: current_date.year mod 100 x_label: "Year (from " + iteration_one + ')' y_label: "Area (sqm)" background: # darkgrey
			color: # white
			{
				list<rgb> type_colors;
				loop t over: types_area
				{
					rgb t_color <- colorMap[t];
					add t_color to: type_colors;
				}

				datalist count_area.keys value: count_area.values color: type_colors marker_shape: marker_empty;

				//data "home" value:count_area[string(home)] color:colorMap[string(home)]; 
			}

		}

		display "unit_storey"
		{
			chart "Home Units v.s. Building Level" type: histogram x_label: "Unit at each level" y_label: "Number of units"
			{ //x_serie_labels:current_date.year mod 100 x_label:"Cycle" y_label:"Area (sqm)" background:#darkgrey color:#white{
				datalist count_storey.keys value: count_storey.values;
			}

		}

		display "population_capacity"
		{
			chart "Total Population v.s. Home Capacity" type: series x_label: "Year (from " + iteration_one + ')' x_serie_labels: current_date.year mod 100 y_label: 'Number of people'
			{
				datalist ['Population', 'Capacity'] value: [total_population, total_capacity] color: [# blue, # red] marker_shape: marker_empty;
			}

		}

	}

}

experiment 'Batch' type: batch repeat: 30 keep_seed: true
{
	parameter "Unit size" var: unit_xy min: 3 max: 3 step: 1;
	parameter "Space per person" var: space_per_person min: 9 max: 9 step: 3;
	parameter "Units per cycle" var: max_unit_per_cycle min: 15 max: 15 step: 1;
	parameter "batch" var: is_batch <- true; //don't touch this 
	parameter "Scenario" var: running_scenario <- 1; // hypothesis123
}
//
//experiment 'Scenario 2' type: gui
//{
//	parameter "Homes to randomize" var: num_init <- 10;
//	init
//	{
//		running_scenario <- 2;
//	}
//
//	output
//	{
//		display map type: opengl
//		{
//		//species boundary;
//			species greens;
//			species church transparency: 0.5;
//			species temple transparency: 0.5;
//			//species institute;
//			species orphanage;
//			species wat;
//			species cemetery;
//			species school;
//			agents "ground_home" value: home where (each.location.z = 0);
//			agents "other_home" value: home where (each.location.z > 0);
//			species shop;
//			species roads;
//			species paths;
//			graphics 'display_date'
//			{
//				draw string(current_date) at: { 10, 10 } color: # black;
//			}
//
//		}
//
//		display "floor_area" type: java2D
//		{
//			chart "Floor Area of Units" type: series x_serie_labels: current_date.year mod 100 x_label: "Year (from " + iteration_one + ')' y_label: "Area (sqm)" background: # darkgrey
//			color: # white
//			{
//				list<rgb> type_colors;
//				loop t over: types_area
//				{
//					rgb t_color <- colorMap[t];
//					add t_color to: type_colors;
//				}
//
//				datalist count_area.keys value: count_area.values color: type_colors marker_shape: marker_empty;
//
//				//data "home" value:count_area[string(home)] color:colorMap[string(home)]; 
//			}
//
//		}
//
//		display "unit_storey"
//		{
//			chart "Home Units v.s. Building Level" type: histogram x_label: "Unit at each level" y_label: "Number of units"
//			{ //x_serie_labels:current_date.year mod 100 x_label:"Cycle" y_label:"Area (sqm)" background:#darkgrey color:#white{
//				datalist count_storey.keys value: count_storey.values;
//			}
//
//		}
//
//		display "population_capacity"
//		{
//			chart "Total Population v.s. Home Capacity" type: series x_label: "Year (from " + iteration_one + ')' x_serie_labels: current_date.year mod 100 y_label: 'Number of people'
//			{
//				datalist ['Population', 'Capacity'] value: [total_population, total_capacity] color: [# blue, # red] marker_shape: marker_empty;
//			}
//
//		}
//
//	}
//
//}
experiment 'Senario compare' type: batch repeat: 30 keep_seed: true
{
	parameter "batch" var: is_batch <- true;
	parameter "Scenario" var: running_scenario <- 1 min: 1 max: 3 step: 1;
	parameter "Output scenario" var: output_scenario <- true;
}