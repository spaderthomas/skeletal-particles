return {
	write_paths = {
		main = {
			path = 'boonbane',
			children = {
				screenshots = {
					path = 'screenshots',
					format = {
						name = 'screenshot',
						format = '%s',
					},
				},
				saves = {
					path = 'saves',
					format = {
						name = 'save',
						format = '%s.lua',
					},
				},
			}
		}
	},
	install_paths = {
		skeletal_animations = {
			path = 'skeletal_animations',
			format = {
				name = 'skeletal_animation',
				format = '%s.lua',
			}
		},
		skeletons = {
			path = 'skeleton',
			format = {
				name = 'skeleton',
				format = '%s.lua',
			}
		},
		particle_rigs = {
			path = 'particle_rigs',
			format = {
				name = 'particle_rig',
				format = '%s.lua',
			}
		}
	}
}
