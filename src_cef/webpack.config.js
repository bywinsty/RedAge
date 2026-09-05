const path = require('node:path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const autoprefixer = require('autoprefixer');

const interfacePath = path.resolve(__dirname, '../client_packages/interface');

const variants = {
    main: {
        outputDirectory: 'build',
        htmlFilename: 'index.html',
        publicPath: '',
    },
    ru: {
        outputDirectory: 'buildru',
        htmlFilename: 'index.ru.html',
        publicPath: 'https://cdn.ragemp.pro/',
    },
    en: {
        outputDirectory: 'builden',
        htmlFilename: 'index.en.html',
        publicPath: 'https://cdn.ragemp.pro/',
    },
};

const aliases = {
    '@': path.resolve(__dirname, 'src'),
    api: path.resolve(__dirname, 'src/api'),
    store: path.resolve(__dirname, 'src/store'),
    components: path.resolve(__dirname, 'src/components'),
    router: path.resolve(__dirname, 'src/router/index.js'),
    json: path.resolve(__dirname, 'src/json'),
    lang: path.resolve(__dirname, 'lang'),
};

function postCssLoader(sourceMap) {
    return {
        loader: 'postcss-loader',
        options: {
            sourceMap,
            postcssOptions: {
                config: false,
                plugins: [autoprefixer()],
            },
        },
    };
}

function cssLoader(sourceMap, importLoaders) {
    return {
        loader: 'css-loader',
        options: {
            importLoaders,
            sourceMap,
        },
    };
}

function createConfig(variantName, mode) {
    const variant = variants[variantName] || variants.main;
    const production = mode === 'production';
    const extractCss = MiniCssExtractPlugin.loader;
    const extractCssOptions = {
        publicPath: '../',
    };

    return {
        context: __dirname,
        entry: {
            main: path.resolve(__dirname, 'src/main.js'),
        },
        resolve: {
            alias: aliases,
            extensions: ['.mjs', '.js', '.svelte'],
            mainFields: ['svelte', 'browser', '...'],
            conditionNames: ['svelte', 'browser', '...'],
        },
        target: 'browserslist',
        output: {
            path: interfacePath,
            filename: `${variant.outputDirectory}/bundle.js`,
            publicPath: variant.publicPath,
            assetModuleFilename: '[path][name][ext]',
            libraryTarget: 'umd',
        },
        plugins: [
            new HtmlWebpackPlugin({
                template: path.resolve(__dirname, 'src/index.html'),
                title: 'RedAge',
                filename: variant.htmlFilename,
                inject: 'body',
                scriptLoading: 'blocking',
            }),
            new MiniCssExtractPlugin({
                filename: `${variant.outputDirectory}/bundle.css`,
            }),
        ],
        module: {
            rules: [
                {
                    test: /\.(svelte|svelte\.js)$/,
                    exclude: /node_modules/,
                    use: {
                        loader: 'svelte-loader',
                        options: {
                            compilerOptions: {
                                dev: !production,
                                compatibility: {
                                    componentApi: 4,
                                },
                            },
                            emitCss: production,
                            hotReload: !production,
                        },
                    },
                },
                {
                    test: /\.css$/i,
                    use: [
                        { loader: extractCss, options: extractCssOptions },
                        cssLoader(!production, 1),
                        postCssLoader(!production),
                    ],
                },
                {
                    test: /\.s[ac]ss$/i,
                    use: [
                        { loader: extractCss, options: extractCssOptions },
                        cssLoader(!production, 2),
                        postCssLoader(!production),
                        {
                            loader: 'sass-loader',
                            options: {
                                api: 'modern',
                                sourceMap: !production,
                            },
                        },
                    ],
                },
                {
                    test: /\.(jpe?g|png|svg|gif)$/i,
                    type: 'asset/resource',
                    generator: {
                        filename: '[path][name][ext]',
                    },
                },
                {
                    test: /\.(webm|ttf|eot|woff2?|ogg|mp3|wav|mpe?g)(\?[a-z0-9=&.]+)?$/i,
                    type: 'asset/resource',
                    generator: {
                        filename: '[path][name][ext]',
                    },
                },
                {
                    test: /node_modules[\\/]svelte[\\/].*\.mjs$/,
                    resolve: {
                        fullySpecified: false,
                    },
                },
            ],
        },
        mode,
        devtool: production ? false : 'source-map',
        devServer: {
            static: false,
            hot: true,
            compress: true,
            port: 8888,
        },
    };
}

module.exports = (env = {}, argv = {}) => {
    const variantName = typeof env.variant === 'string' ? env.variant : 'main';
    const mode = argv.mode || process.env.NODE_ENV || 'development';
    return createConfig(variantName, mode);
};
